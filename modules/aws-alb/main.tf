
# public facing Application Load Balancer
resource "aws_alb" "this" {
  name               = "${var.name_prefix}-alb"
  subnets            = var.vpc.public_subnets
  security_groups    = ["${aws_security_group.alb-sg.id}"]
  internal           = false
  load_balancer_type = "application"
  tags               = var.tags
}

resource "aws_alb_target_group" "this" {
  name        = "${var.name_prefix}-tg"
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc.vpc_id
  target_type = "instance"
  tags        = var.tags

  # this is to make sure alb arn is ready when target group is created
  # target group arn is used by ECS service and ALB should be ready
  depends_on = [aws_alb.this]
}

# Redirect HTTP traffic from the ALB to the target group
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.this.arn
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
      target_group_arn = aws_alb_target_group.this.arn
      type             = "forward"
    }
  }
}

# Redirect HTTPS traffic from the ALB to the target group
resource "aws_alb_listener" "https" {
  # run if https is enabled
  count = var.alb_listener_enable_https ? 1 : 0

  load_balancer_arn = aws_alb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.validation[0].certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }

  depends_on = [
    aws_acm_certificate_validation.validation,
  ]
}


# Look up the public DNS zone
# there is no check for the zone value, since this is a data source it will fail if not exists
data "aws_route53_zone" "public" {
  # execute if fqdn is not null and not empty string
  count = coalesce(var.app_fqdn, false) == var.app_fqdn ? 1 : 0

  name         = var.app_route53_zone
  private_zone = false

  lifecycle {
    precondition {
      condition     = coalesce(var.app_route53_zone, false) == var.app_route53_zone
      error_message = "DNS zone (app_route53_zone) should be provided when fqdn is given."
    }
  }
}

# Create an SSL certificate
resource "aws_acm_certificate" "app_ssl" {
  # run if https is enabled
  count = var.alb_listener_enable_https ? 1 : 0

  domain_name       = aws_route53_record.app[0].fqdn
  validation_method = "DNS"
  tags              = var.tags

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = coalesce(var.app_fqdn, false) == var.app_fqdn
      error_message = "App fqdn (app_fqdn) should be provided when https is enabled."
    }
  }
}

resource "aws_route53_record" "cert_validation_record" {
  # run if https is enabled
  count = var.alb_listener_enable_https ? 1 : 0

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.app_ssl[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.app_ssl[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.app_ssl[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.public[0].zone_id
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
  # run if https is enabled
  count = var.alb_listener_enable_https ? 1 : 0

  timeouts {
    create = "5m"
  }

  certificate_arn         = aws_acm_certificate.app_ssl[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation_record[0].fqdn]
}

# standard route53 DNS record for "app" pointing to an ALB
resource "aws_route53_record" "app" {
  # execute if fqdn is provided
  count = coalesce(var.app_fqdn, false) == var.app_fqdn ? 1 : 0

  zone_id = data.aws_route53_zone.public[0].zone_id
  name    = var.app_fqdn
  type    = "A"

  alias {
    name                   = aws_alb.this.dns_name
    zone_id                = aws_alb.this.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    precondition {
      condition     = trimsuffix(var.app_fqdn, var.app_route53_zone) == replace(var.app_fqdn, var.app_route53_zone, "") && one(regexall(var.app_route53_zone, var.app_fqdn)) == var.app_route53_zone
      error_message = "Domain ${var.app_route53_zone} should match fqdn ${var.app_fqdn}."
    }
  }

}
