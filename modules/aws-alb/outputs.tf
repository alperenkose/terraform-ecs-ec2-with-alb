
output "app_alb_domain" {
  description = "Auto assigned domain for the ALB"
  value       = aws_alb.this.dns_name
}

output "app_fqdn" {
  description = "FQDN pointing to the ALB for the application"
  value       = length(aws_route53_record.app) > 0 ? one(aws_route53_record.app).fqdn : null
}

output "alb" {
  description = "Application Load Balancer"
  value       = aws_alb.this
}

output "alb_security_group" {
  description = "ALB Security Group"
  value       = aws_security_group.alb-sg
}

output "alb_target_group" {
  description = "ALB Target Group"
  value       = aws_alb_target_group.this
}

