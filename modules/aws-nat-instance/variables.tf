
variable "instance_name" {
  default = "nat-instance"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_pair_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  description = "Subnet to deploy the NAT instance."
  type        = string
}

variable "private_subnets_cidr_blocks" {
  description = "Private subnets which outbound nat will be allowed on this instance."
  type        = list(any)
}

variable "private_route_table_ids" {
  description = "List of route table ids of private subnets"
  type        = list(any)
}
