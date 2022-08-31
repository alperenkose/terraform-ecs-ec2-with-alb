

resource "aws_ecs_task_definition" "this" {
  family                = "${local.name_prefix}-${var.container_name}"
  container_definitions = templatefile("templates/ecs-task.json.tpl", local.container_template_vars)
}

# public facing Application Load Balancer
resource "aws_alb" "ecs-alb" {
  name               = "${local.name_prefix}-ecs-alb"
  subnets            = module.vpc.public_subnets
  security_groups    = ["${aws_security_group.ecs-alb-sg.id}"]
  internal           = false
  load_balancer_type = "application"
}

resource "aws_alb_target_group" "ecs-tg" {
  name        = "${local.name_prefix}-ecs-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"
}

# Redirect HTTP traffic from the ALB to the target group
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.ecs-alb.arn
  port              = 80
  protocol          = "HTTP"

  # redirect to https if enabled
  dynamic "default_action" {
    for_each = var.alb_listener_enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  # forward to target group if https is disabled
  dynamic "default_action" {
    for_each = var.alb_listener_enable_https ? [] : [1]
    content {
      target_group_arn = aws_alb_target_group.ecs-tg.arn
      type             = "forward"
    }
  }
}


# Redirect HTTPS traffic from the ALB to the target group
resource "aws_alb_listener" "https" {
  # run if https is enabled
  count = var.alb_listener_enable_https ? 1 : 0

  load_balancer_arn = aws_alb.ecs-alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.validation.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.ecs-tg.arn
    type             = "forward"
  }

  depends_on = [
    aws_acm_certificate_validation.validation,
  ]
}

resource "aws_ecs_service" "this" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_task_desired_count

  # launch_type     = "EC2"
  # can not provide launch type with capacity provider
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs-default-capacity-provider.name
    weight            = 100
  }

  # Since this is the default no need to point it, for some reason it tried to recreate it with this.
  # iam_role        = aws_iam_service_linked_role.AWSServiceRoleForECS.arn

  # associating ecs service with ALB target group, this allows ALB to forward requests to ECS
  load_balancer {
    target_group_arn = aws_alb_target_group.ecs-tg.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  # allow autoscaling of tasks without terraform plan showing difference
  lifecycle {
    ignore_changes = [desired_count]
  }


  # @todo: To prevent a race condition during service deletion, make sure to set depends_on to the related aws_iam_role_policy;
  # otherwise, the policy may be destroyed too soon and the ECS service will then get stuck in the DRAINING state.

  depends_on = [
    aws_alb_listener.http,
    aws_alb_listener.https,
  ]
}


# Look up the public DNS zone
data "aws_route53_zone" "public" {
  name         = var.app_route53_zone
  private_zone = false
}

# Create an SSL certificate
resource "aws_acm_certificate" "app_ssl" {
  domain_name       = aws_route53_record.app.fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_record" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.app_ssl.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.app_ssl.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.app_ssl.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.public.zone_id
  ttl             = 60
}

# Couldn't use this block since the domain_validation_options are not defined before runtime and
# for_each doesn't know how many times to run this block, hence it requires targeting to create resources in order
# Since this is a single domain ssl we have used dvo [0] in cert validation record to overcome targeting

# resource "aws_route53_record" "cert_validation_record" {
#   for_each = {
#     for dvo in aws_acm_certificate.app_ssl.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.public.zone_id
# }


# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "validation" {
  timeouts {
    create = "5m"
  }

  certificate_arn         = aws_acm_certificate.app_ssl.arn
  validation_record_fqdns = [aws_route53_record.cert_validation_record.fqdn]
}


# standard route53 DNS record for "app" pointing to an ALB
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.app_fqdn
  # name    = "${var.demo_dns_name}.${data.aws_route53_zone.public.name}"
  type = "A"
  alias {
    name                   = aws_alb.ecs-alb.dns_name
    zone_id                = aws_alb.ecs-alb.zone_id
    evaluate_target_health = false
  }
}

