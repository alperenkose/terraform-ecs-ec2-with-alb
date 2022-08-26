
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets

  create_igw = true

  tags = var.vpc_tags
}



# # Internet VPC
# resource "aws_vpc" "infra-task-ecs-vpc" {
#   cidr_block           = "10.1.0.0/16"
#   instance_tenancy     = "default"
#   enable_dns_support   = "true"
#   enable_dns_hostnames = "true"
#   enable_classiclink   = "false"
#   tags = {
#     Name = "infra-task-ecs-vpc"
#   }
# }

# # Subnets
# resource "aws_subnet" "infra-task-ecs-public-1" {
#   vpc_id                  = aws_vpc.infra-task-ecs-vpc.id
#   cidr_block              = "10.1.1.0/24"
#   map_public_ip_on_launch = "true"
#   # why not take this from vars.tf
#   availability_zone       = "us-east-1a"

#   tags = {
#     Name = "infra-task-ecs-public-1"
#   }
# }

# resource "aws_subnet" "infra-task-ecs-public-2" {
#   vpc_id                  = aws_vpc.infra-task-ecs-vpc.id
#   cidr_block              = "10.1.2.0/24"
#   map_public_ip_on_launch = "true"
#   availability_zone       = "us-east-1b"

#   tags = {
#     Name = "infra-task-ecs-public-2"
#   }
# }

# resource "aws_subnet" "infra-task-ecs-private-1" {
#   vpc_id                  = aws_vpc.infra-task-ecs-vpc.id
#   cidr_block              = "10.1.3.0/24"
#   map_public_ip_on_launch = "false"
#   availability_zone       = "us-east-1a"

#   tags = {
#     Name = "infra-task-ecs-private-1"
#   }
# }

# resource "aws_subnet" "infra-task-ecs-private-2" {
#   vpc_id                  = aws_vpc.infra-task-ecs-vpc.id
#   cidr_block              = "10.1.4.0/24"
#   map_public_ip_on_launch = "false"
#   availability_zone       = "us-east-1b"

#   tags = {
#     Name = "infra-task-ecs-private-2"
#   }
# }


# # Internet GW
# resource "aws_internet_gateway" "infra-task-ecs-gw" {
#   vpc_id = aws_vpc.infra-task-ecs-vpc.id

#   tags = {
#     Name = "infra-task-ecs-gw"
#   }
# }

# # route tables
# resource "aws_route_table" "infra-task-ecs-rtb-public" {
#   vpc_id = aws_vpc.infra-task-ecs-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.infra-task-ecs-gw.id
#   }

#   tags = {
#     Name = "infra-task-ecs-rtb-public"
#   }
# }

# # route associations public
# resource "aws_route_table_association" "infra-task-ecs-public-1-a" {
#   subnet_id      = aws_subnet.infra-task-ecs-public-1.id
#   route_table_id = aws_route_table.infra-task-ecs-rtb-public.id
# }

# resource "aws_route_table_association" "infra-task-ecs-public-2-a" {
#   subnet_id      = aws_subnet.infra-task-ecs-public-2.id
#   route_table_id = aws_route_table.infra-task-ecs-rtb-public.id
# }


