
resource "aws_security_group" "alb-sg" {
  vpc_id      = var.vpc.vpc_id
  name        = "${var.name_prefix}-alb-sg"
  description = "Security Group for ALB"

  dynamic "egress" {
    for_each = var.alb_security_group_egress_rules

    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = "tcp"
      cidr_blocks     = try(egress.value.cidr_blocks, null)
      security_groups = try(egress.value.security_groups, null)
    }
  }

  dynamic "ingress" {
    for_each = var.alb_security_group_ingress_rules

    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = "tcp"
      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
    }
  }

  tags = merge(var.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
    }
  )
}
