# resource "aws_key_pair" "infra-task-keypair" {
#   key_name   = "infra-task-keypair"
#   public_key = file(var.PATH_TO_PUBLIC_KEY)
#   lifecycle {
#     ignore_changes = [public_key]
#   }
# }

# check whether provided key pair exists on AWS
data "aws_key_pair" "project-keypair" {
  key_name           = var.ec2_key_pair
  include_public_key = true
}
