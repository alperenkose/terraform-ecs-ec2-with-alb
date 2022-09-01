resource "aws_security_group" "ecs-sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security Group for ECS"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # allow traffic from ALB security group to ECS
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs-alb-sg.id]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

resource "aws_security_group" "ecs-alb-sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "${local.name_prefix}-ecs-alb-sg"
  description = "Security Group for ALB"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = local.alb_listener_ports

    content {
      from_port   = ingress.key
      to_port     = ingress.key
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "${local.name_prefix}-ecs-alb-sg"
  }
}
