

# Get the latest Amazon2 AMI
data "aws_ami" "latest_amzn2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel*-ebs"]
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


# ECS NAT Instance to allow private subnets internet connection
resource "aws_instance" "ecs-nat" {
  ami                         = data.aws_ami.latest_amzn2.id
  instance_type               = var.nat_instance_type
  associate_public_ip_address = "true"
  subnet_id                   = module.vpc.public_subnets[0]
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.ecs-nat-sg.id]

  key_name = data.aws_key_pair.project-keypair.key_name

  user_data = templatefile("templates/nat-instance-masquerade.sh.tpl", {
    private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  })

  tags = {
    Name = "${local.name_prefix}-ecs-nat"
    Role = "nat"
  }
}

# Add route to NAT instance in private subnets
resource "aws_route" "ecs-nat-route" {
  count = 2

  route_table_id         = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.ecs-nat.primary_network_interface_id
}
