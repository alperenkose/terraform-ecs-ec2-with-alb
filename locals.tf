locals {
  name_prefix = var.project_name
  vpc_name    = coalesce(var.vpc_name, "${local.name_prefix}-ecs-vpc")

  container_template_vars = {
    container_name  = "${var.container_name}",
    container_image = "${var.container_image}",
    container_cpu   = var.container_cpu,
    container_mem   = var.container_mem,
    container_port  = var.container_port
  }
}
