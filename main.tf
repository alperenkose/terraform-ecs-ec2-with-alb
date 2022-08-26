

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

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "ecs-alb-listener" {
  load_balancer_arn = aws_alb.ecs-alb.arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol
  default_action {
    target_group_arn = aws_alb_target_group.ecs-tg.arn
    type             = "forward"
  }
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

  # @todo: This might be needed to allow autoscaling of tasks without terraform plan showing difference
  # lifecycle {
  #   ignore_changes = [desired_count]
  # }


  # @todo: To prevent a race condition during service deletion, make sure to set depends_on to the related aws_iam_role_policy;
  # otherwise, the policy may be destroyed too soon and the ECS service will then get stuck in the DRAINING state.
  depends_on = [
    aws_alb_listener.ecs-alb-listener,
  ]
}

