
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
}

module "nat_instance" {
  source = "./modules/aws-nat-instance"

  instance_name               = "${local.name_prefix}-ecs-nat"
  key_pair_name               = data.aws_key_pair.project-keypair.key_name
  vpc_id                      = module.vpc.vpc_id
  public_subnet_id            = module.vpc.public_subnets[0]
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  private_route_table_ids     = module.vpc.private_route_table_ids
}

# Get the latest ECS AMI
data "aws_ami" "latest_ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm*-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}

# ECS cluster
resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${local.name_prefix}-ecs-cluster"

  depends_on = [module.vpc]
}

# Lunch configuration to be used for creating new EC2 instances
resource "aws_launch_configuration" "ecs-launchconfig" {
  name_prefix          = "${local.name_prefix}-ecs-launchconfig"
  image_id             = data.aws_ami.latest_ecs.id
  instance_type        = var.ecs_instance_type
  key_name             = data.aws_key_pair.project-keypair.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-role.id
  security_groups      = [aws_security_group.ecs-sg.id]

  user_data = templatefile("templates/ecs-ec2-userdata.sh.tpl", {
    ecs_cluster_name = "${local.name_prefix}-ecs-cluster"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs-autoscaling" {
  name                 = "${local.name_prefix}-ecs-autoscaling"
  vpc_zone_identifier  = module.vpc.private_subnets
  launch_configuration = aws_launch_configuration.ecs-launchconfig.name
  min_size             = var.ec2_autoscaling_min_size
  max_size             = var.ec2_autoscaling_max_size

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-ecs-ec2-container"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs-capacity-providers" {
  cluster_name = aws_ecs_cluster.ecs-cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs-default-capacity-provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs-default-capacity-provider.name
  }
}

resource "aws_ecs_capacity_provider" "ecs-default-capacity-provider" {
  name = "${local.name_prefix}-ecs-default-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs-autoscaling.arn
    # managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = var.ec2_autoscaling_target_capacity
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  family                = "${local.name_prefix}-${var.container_name}"
  container_definitions = templatefile("templates/ecs-task.json.tpl", local.container_template_vars)
}

resource "aws_ecs_service" "this" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_task_desired_count

  # service will be using default capacity provider from cluster

  # since this is the default no need to point it, for some reason it tried to recreate it with this.
  # iam_role        = aws_iam_service_linked_role.AWSServiceRoleForECS.arn

  # associating ecs service with ALB target group, this allows ALB to forward requests to ECS
  load_balancer {
    target_group_arn = aws_alb_target_group.ecs-tg.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  # allow autoscaling of tasks without terraform plan showing difference
  lifecycle {
    ignore_changes = [desired_count, capacity_provider_strategy]
  }

  # To prevent a race condition during service deletion, make sure to set depends_on to the related aws_iam_role_policy;
  # otherwise, the policy may be destroyed too soon and the ECS service will then get stuck in the DRAINING state.
  depends_on = [
    aws_alb_listener.http,
    aws_alb_listener.https,
    aws_iam_role.ecs-instance-role
  ]
}

resource "aws_appautoscaling_target" "ecs-app-target" {
  max_capacity = var.ecs_task_autoscaling_max
  min_capacity = var.ecs_task_autoscaling_min

  resource_id        = "service/${aws_ecs_cluster.ecs-cluster.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs-app-scaling" {
  name               = "${local.name_prefix}-ecs-app-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs-app-target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-app-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs-app-target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_alb.ecs-alb.arn_suffix}/${aws_alb_target_group.ecs-tg.arn_suffix}"
    }

    target_value       = var.ecs_task_autoscaling_request_count
    scale_in_cooldown  = var.ecs_task_scale_in_cooldown
    scale_out_cooldown = var.ecs_task_scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs-app-target]
}
