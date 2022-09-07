locals {
  name_prefix = var.project_name
  vpc_name    = coalesce(var.vpc_name, "${local.name_prefix}-ecs-vpc")
}
