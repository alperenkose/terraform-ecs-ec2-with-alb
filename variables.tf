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

variable "project_name" {
  type     = string
  nullable = false

  validation {
    condition     = length(var.project_name) > 0
    error_message = "The project_name must be provided."
  }
}

variable "tags" {
  description = "Tags to associate with created resources."
  default     = {}
  type        = map(any)
}

variable "ecs" {
  description = <<-EOF
ECS object to create.
Values are input variables for the ecs sub-module:
- `ecs_instance_type`: (optional|string) EC2 instance type to be used for the autoscaling group.
- `ec2_autoscaling_min_size`: (optional|number) Min size for EC2 autoscaling group.
- `ec2_autoscaling_max_size`: (optional|number) Max size for EC2 autoscaling group.
- `ec2_autoscaling_target_capacity`: (optional|number) Per instance capacity percentage to target for autoscaling.
- `ecs_task_desired_count`: (optional|number) Desired number of running ECS tasks.
- `ecs_task_autoscaling_min`: (optional|number) Min number of running ECS tasks for service autoscaling.
- `ecs_task_autoscaling_max`: (optional|number) Max number of running ECS tasks for service autoscaling.
- `ecs_task_autoscaling_request_count`: (optional|number) ALB request count per task to trigger autoscaling.
- `ecs_task_scale_in_cooldown`: (optional|number) Cooldown period after scaling in.
- `ecs_task_scale_out_cooldown`: (optional|number) Cooldown period after scaling out.
- `container_name`: (optional|string) Name of container to deploy.
- `container_image`: (optional|string) Image for the container to deploy.
- `container_cpu`: (optional|number) CPU request of the container.
- `container_mem`: (optional|number) Memory request of the container.
- `container_port`: (optional|number) Container listening port.

Example:

```
{
  ecs_instance_type = "t2.medium"
  ec2_autoscaling_target_capacity = 90
  container_image = "nginxdemos/hello:latest"
}
```

EOF
  default     = {}
}

variable "alb" {
  description = <<-EOF
Application Load Balancer object to create.
Values are input variables for the alb sub-module:
- `app_route53_zone`: (optional|string) DNS Zone name to be used for creating app fqdn and cert validation record.
- `app_fqdn`: (optional|string) FQDN for the application to be hosted, domain should match with zone.
- `alb_listener_enable_https`: (optional|bool) Whether to listen on HTTPS or not.
- `alb_security_group_ingress_rules`: (optional|list) List of security group ingress rules.
- `alb_security_group_egress_rules`: (optional|list) List of security group egress rules.

Example:

```
{
  app_route53_zone = "example.com"
  app_fqdn = "my-ecs-app.example.com"
  alb_security_group_ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

EOF
  default     = {}
}
