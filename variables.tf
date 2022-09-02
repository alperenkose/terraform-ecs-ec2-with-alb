variable "aws_profile" {
  default = "default"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = null
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "vpc_azs" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_public_subnets" {
  type    = list(any)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "vpc_private_subnets" {
  type    = list(any)
  default = ["10.1.3.0/24", "10.1.4.0/24"]
}

variable "ec2_key_pair" {
  type     = string
  nullable = false

  validation {
    condition     = length(var.ec2_key_pair) > 0
    error_message = "The ec2_key_pair must be provided."
  }
}

variable "ecs_instance_type" {
  default = "t2.micro"
}

variable "ec2_autoscaling_min_size" {
  type    = number
  default = 1
}

variable "ec2_autoscaling_max_size" {
  type    = number
  default = 3
}

variable "ec2_autoscaling_target_capacity" {
  type    = number
  default = 80
}

variable "ecs_task_desired_count" {
  type    = number
  default = 1
}

variable "ecs_task_autoscaling_min" {
  type    = number
  default = 1
}

variable "ecs_task_autoscaling_max" {
  type    = number
  default = 5
}

variable "ecs_task_autoscaling_request_count" {
  type    = number
  default = 2
}

variable "ecs_task_scale_in_cooldown" {
  type    = number
  default = 120
}

variable "ecs_task_scale_out_cooldown" {
  type    = number
  default = 120
}

variable "project_name" {
  type     = string
  nullable = false

  validation {
    condition     = length(var.project_name) > 0
    error_message = "The project_name must be provided."
  }
}

variable "container_name" {
  type    = string
  default = "nginxdemos-hello"
}

variable "container_image" {
  type    = string
  default = "nginxdemos/hello:latest"
}

variable "container_cpu" {
  type    = number
  default = 128
}

variable "container_mem" {
  type    = number
  default = 128
}

variable "container_port" {
  type    = number
  default = 80
}

variable "alb_listener_enable_https" {
  type    = bool
  default = false
}

variable "app_route53_zone" {
  type    = string
  default = null
}

variable "app_fqdn" {
  type    = string
  default = null
}
