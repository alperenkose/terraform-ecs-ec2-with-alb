
output "app_alb_domain" {
  description = "Auto assigned domain for the ALB"
  value       = aws_alb.ecs-alb.dns_name
}

output "app_fqdn" {
  description = "FQDN pointing to the ALB for the application"
  value       = length(aws_route53_record.app) > 0 ? one(aws_route53_record.app).fqdn : null
}
