
# check whether provided key pair exists on AWS
data "aws_key_pair" "project-keypair" {
  key_name           = var.ec2_key_pair
  include_public_key = true
}
