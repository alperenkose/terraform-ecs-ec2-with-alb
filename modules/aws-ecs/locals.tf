locals {
  container_template_vars = {
    container_name  = "${var.container_name}",
    container_image = "${var.container_image}",
    container_cpu   = var.container_cpu,
    container_mem   = var.container_mem,
    container_port  = var.container_port
  }

}
