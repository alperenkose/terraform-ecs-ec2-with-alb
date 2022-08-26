
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
}

# Lunch configuration to be used for creating new EC2 instances
resource "aws_launch_configuration" "ecs-launchconfig" {
  name_prefix = "${local.name_prefix}-ecs-launchconfig"
  image_id             = data.aws_ami.latest_ecs.id
  instance_type        = var.ecs_instance_type
  key_name             = data.aws_key_pair.project-keypair.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-role.id
  security_groups      = [aws_security_group.ecs-sg.id]

  # user_data            = "#!/bin/bash\necho 'ECS_CLUSTER=${local.name_prefix}-ecs-cluster' > /etc/ecs/ecs.config\nstart ecs"
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
  min_size             = var.ecs_autoscaling_min_size
  max_size             = var.ecs_autoscaling_max_size

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
      target_capacity = 80
    }
  }
}
