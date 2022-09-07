
variable "name_prefix" {
  type    = string
  default = "app"
}

variable "tags" {
  description = "Tags to associate with created resources."
  default     = {}
  type        = map(any)
}

variable "vpc" {
  description = "AWS VPC module object"
  type = object({
    vpc_id          = string
    public_subnets  = list(any)
    private_subnets = list(any)
  })
}

variable "app_route53_zone" {
  description = "Route53 DNS zone in which to create app fqdn and cert validation records"
  type        = string
  default     = null
}

variable "app_fqdn" {
  description = "Application FQDN to access."
  type        = string
  default     = null
}

# the value for this doesn't matter when target group is ECS with dynamic port assignment
variable "target_group_port" {
  description = "Target Group Port - ignored with ECS dynamic port assignment"
  type        = number
  nullable    = false
  default     = 80
}

variable "alb_listener_enable_https" {
  description = "Whether to listen on HTTPS or not."
  type        = bool
  nullable    = false
  default     = false
}

variable "alb_security_group_ingress_rules" {
  description = <<-EOF
List of ingress rules for the Application Load Balancer.
Options for an ingress rule:
- `from_port` - (required|number) Starting port number for ingress rule.
- `to_port` - (required|number) Ending port number for ingress rule.
- `cidr_blocks` - (optional|list) CIDR blocks to allow access from.
- `security_groups` - (optional|list) Security group IDs to allow access from.

Example:

```
[
  {
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.my-sg.id]
  },
  {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
]
```

EOF
  type        = any
  nullable    = false
  default = [
    {
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "alb_security_group_egress_rules" {
  description = <<-EOF
List of egress rules for the Application Load Balancer.
Options for an egress rule:
- `from_port` - (required|number) Starting port number for egress rule.
- `to_port` - (required|number) Ending port number for egress rule.
- `cidr_blocks` - (optional|list) CIDR blocks to allow access to.
- `security_groups` - (optional|list) Security group IDs to allow access to.

Example:

```
[
  {
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.my-sg.id]
  },
  {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
]
```

EOF
  type        = any
  nullable    = false
  default = [
    {
      from_port   = 0
      to_port     = 65535
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
