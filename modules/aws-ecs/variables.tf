
variable "name_prefix" {
  type    = string
  default = "app"
}

variable "vpc" {
  type = object({
    vpc_id          = string
    public_subnets  = list(any)
    private_subnets = list(any)
  })
}

variable "key_pair_name" {
  type = string
}

variable "tags" {
  description = "Tags to associate with created resources."
  default     = {}
  type        = map(any)
}

variable "ecs_security_group_ingress_rules" {
  description = <<-EOF
List of ingress rules for the ECS launched EC2 instances.
Options for an ingress rule:
- `from_port` - (required|number) Starting port number for ingress rule.
- `to_port` - (required|number) Ending port number for ingress rule.
- `protocol` - (required|string) Protocol.
- `cidr_blocks` - (optional|list) CIDR blocks to allow access from.
- `security_groups` - (optional|list) Security group IDs to allow access from.

Example:

```
[
  {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.my-sg.id]
  },
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = module.vpc.vpc_cidr_block
  }
]
```

EOF
  type        = any
  nullable    = false
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "ecs_security_group_egress_rules" {
  description = <<-EOF
List of egress rules for the ECS launched EC2 instances.
Options for an egress rule:
- `from_port` - (required|number) Starting port number for egress rule.
- `to_port` - (required|number) Ending port number for egress rule.
- `protocol` - (required|string) Protocol.
- `cidr_blocks` - (optional|list) CIDR blocks to allow access to.
- `security_groups` - (optional|list) Security group IDs to allow access to.

Example:

```
[
  {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.my-sg.id]
  },
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = module.vpc.vpc_cidr_block
  }
]
```

EOF
  type        = any
  nullable    = false
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "ecs_instance_type" {
  type     = string
  nullable = false
  default  = "t2.micro"
}

variable "ec2_autoscaling_min_size" {
  type     = number
  nullable = false
  default  = 1
}

variable "ec2_autoscaling_max_size" {
  type     = number
  nullable = false
  default  = 3
}

variable "ec2_autoscaling_target_capacity" {
  type     = number
  nullable = false
  default  = 80
}

variable "ecs_task_desired_count" {
  type     = number
  nullable = false
  default  = 1
}

variable "ecs_task_autoscaling_min" {
  type     = number
  nullable = false
  default  = 1
}

variable "ecs_task_autoscaling_max" {
  type     = number
  nullable = false
  default  = 5
}

variable "ecs_target_tracking_resource_label" {
  description = "Resource label for target tracking scaling policy metric."
  type        = string
  nullable    = false
}

variable "ecs_task_autoscaling_request_count" {
  type     = number
  nullable = false
  default  = 2
}

variable "ecs_task_scale_in_cooldown" {
  type     = number
  nullable = false
  default  = 120
}

variable "ecs_task_scale_out_cooldown" {
  type     = number
  nullable = false
  default  = 120
}

variable "container_name" {
  type     = string
  nullable = false
  default  = "nginxdemos-hello"
}

variable "container_image" {
  type     = string
  nullable = false
  default  = "nginxdemos/hello:latest"
}

variable "container_cpu" {
  type     = number
  nullable = false
  default  = 128
}

variable "container_mem" {
  type     = number
  nullable = false
  default  = 128
}

variable "container_port" {
  type     = number
  nullable = false
  default  = 80
}

variable "alb_target_group_arn" {
  type     = string
  nullable = false
}
