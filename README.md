
ECS Deployment(EC2-based) with ALB
==================================

Build an ECS cluster with EC2 capacity provider behind an Application Load Balancer.

Creates a dedicated VPC to run the EC2 workload.

VPC subnets, ecs task container details, autoscaling group and task autoscaling are configurable. 
Project name(project\_name) and key pair name(ec2\_key\_pair) are required input variables. See `variables.tf` for optional input variables.

Requirements
------------

* Need to create S3 bucket and Dynamodb table for S3 backend.
* Route53 DNS zone should be present on AWS if custom domain is required. In that case both DNS zone name (app\_route53\_zone) and FQDN for the application (app\_fqdn) should be provided within the alb input variable.

Usage
-----

Create the `config.s3.tfbackend` file based on the example file providing S3 remote backend details for storing state. 

Provide backend configuration on the init command.

    terraform init -backend-config=config.s3.backend
    
Optionally check terraform.tfvars.example for input variables.

