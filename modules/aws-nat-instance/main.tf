
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

# NAT Instance to allow private subnets internet connection
resource "aws_instance" "nat" {
  ami                         = data.aws_ami.latest_amzn2.id
  instance_type               = var.instance_type
  associate_public_ip_address = "true"
  subnet_id                   = var.public_subnet_id
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.nat-sg.id]

  key_name = var.key_pair_name

  user_data = templatefile("${path.module}/templates/nat-instance-masquerade.sh.tpl", {
    private_subnets_cidr_blocks = var.private_subnets_cidr_blocks
  })

  tags = merge(var.tags,
    {
      Name = var.instance_name,
      Role = "nat"
    }
  )
}

# Add route to NAT instance in private subnets
resource "aws_route" "nat-route" {
  count = length(var.private_route_table_ids)

  route_table_id         = element(var.private_route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}

# NAT instance security group
resource "aws_security_group" "nat-sg" {
  vpc_id      = var.vpc_id
  name        = "${var.instance_name}-nat-sg"
  description = "Security group for NAT instance"
  tags        = var.tags

  ingress = [
    {
      description      = "Default ingress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]

  egress = [
    {
      description      = "Default egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]
}
