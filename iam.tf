
# below IAM service linked roles are automatically created

# # AWSServiceRoleForECS
# resource "aws_iam_service_linked_role" "AWSServiceRoleForECS" {
#   aws_service_name = "ecs.amazonaws.com"
#   description      = "Role to enable Amazon ECS to manage your cluster."
# }
# # if it already exists, import it like:
# # terraform import aws_iam_service_linked_role.AWSServiceRoleForECS arn:aws:iam::129965719860:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS


# # AWSServiceRoleForAutoScaling
# resource "aws_iam_service_linked_role" "AWSServiceRoleForAutoScaling" {
#   aws_service_name = "autoscaling.amazonaws.com"
#   description      = "Default Service-Linked Role enables access to AWS Services and Resources used or managed by Auto Scaling"
# }
# # if it already exists, import it like:
# # terraform import aws_iam_service_linked_role.AWSServiceRoleForAutoScaling arn:aws:iam::129965719860:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling


# ecs-instance-role - used in ECS cluster configuration to be assigned to EC2 instances
resource "aws_iam_role" "ecs-instance-role" {
  name               = "ecs-instance-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

# ecs-instance-role instance profile - in order to assign to EC2 instances
resource "aws_iam_instance_profile" "ecs-instance-role" {
  name = "ecs-instance-role"
  role = aws_iam_role.ecs-instance-role.name
}

# Policy for ecs-instance-role
resource "aws_iam_policy_attachment" "ecs-intance-role-policy" {
  name       = "ecs-intance-role-policy"
  roles      = [aws_iam_role.ecs-instance-role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

