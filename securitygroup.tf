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

  ingress {
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-alb-sg"
  }
}

# NAT instance security group
resource "aws_security_group" "ecs-nat-sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "${local.name_prefix}-ecs-nat-sg"
  description = "Security group for NAT instance"

  ingress = [
    {
      description      = "Default ingress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]

  egress = [
    {
      description      = "Default egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]
}
