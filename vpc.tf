
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

module "nat_instance" {
  source = "./modules/aws-nat-instance"

  instance_name               = "${local.name_prefix}-ecs-nat"
  key_pair_name               = data.aws_key_pair.project-keypair.key_name
  vpc_id                      = module.vpc.vpc_id
  public_subnet_id            = module.vpc.public_subnets[0]
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  private_route_table_ids     = module.vpc.private_route_table_ids
}
