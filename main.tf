
# check whether provided key pair exists on AWS
data "aws_key_pair" "project-keypair" {
  key_name           = var.ec2_key_pair
  include_public_key = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets

  create_igw = true
  tags       = var.tags
}

module "nat_instance" {
  source = "./modules/aws-nat-instance"

  instance_name               = "${local.name_prefix}-ecs-nat"
  key_pair_name               = data.aws_key_pair.project-keypair.key_name
  vpc_id                      = module.vpc.vpc_id
  public_subnet_id            = module.vpc.public_subnets[0]
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  private_route_table_ids     = module.vpc.private_route_table_ids
  tags                        = var.tags
}

module "ecs" {
  source = "./modules/aws-ecs"

  name_prefix                        = local.name_prefix
  vpc                                = module.vpc
  key_pair_name                      = data.aws_key_pair.project-keypair.key_name
  alb_target_group_arn               = module.alb.alb_target_group.id
  ecs_target_tracking_resource_label = "${module.alb.alb.arn_suffix}/${module.alb.alb_target_group.arn_suffix}"

  ecs_instance_type                  = try(var.ecs.ecs_instance_type, null)
  ec2_autoscaling_min_size           = try(var.ecs.ec2_autoscaling_min_size, null)
  ec2_autoscaling_max_size           = try(var.ecs.ec2_autoscaling_max_size, null)
  ec2_autoscaling_target_capacity    = try(var.ecs.ec2_autoscaling_target_capacity, null)
  ecs_task_desired_count             = try(var.ecs.ecs_task_desired_count, null)
  ecs_task_autoscaling_min           = try(var.ecs.ecs_task_autoscaling_min, null)
  ecs_task_autoscaling_max           = try(var.ecs.ecs_task_autoscaling_max, null)
  ecs_task_autoscaling_request_count = try(var.ecs.ecs_task_autoscaling_request_count, null)
  ecs_task_scale_in_cooldown         = try(var.ecs.ecs_task_scale_in_cooldown, null)
  ecs_task_scale_out_cooldown        = try(var.ecs.ecs_task_scale_out_cooldown, null)
  container_name                     = try(var.ecs.container_name, null)
  container_image                    = try(var.ecs.container_image, null)
  container_cpu                      = try(var.ecs.container_cpu, null)
  container_mem                      = try(var.ecs.container_mem, null)
  container_port                     = try(var.ecs.container_port, null)

  ecs_security_group_ingress_rules = [
    { # allow traffic from ALB security group to ECS
      from_port       = 0
      to_port         = 65535
      protocol        = "tcp"
      security_groups = [module.alb.alb_security_group.id]
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  ]

  tags = var.tags
}

module "alb" {
  source = "./modules/aws-alb"

  name_prefix = local.name_prefix
  vpc         = module.vpc

  alb_listener_enable_https = try(var.alb.alb_listener_enable_https, null)
  app_route53_zone          = try(var.alb.app_route53_zone, null)
  app_fqdn                  = try(var.alb.app_fqdn, null)

  alb_security_group_ingress_rules = try(var.alb.alb_security_group_ingress_rules, null)
  alb_security_group_egress_rules  = try(var.alb.alb_security_group_egress_rules, null)

  tags = var.tags
}
