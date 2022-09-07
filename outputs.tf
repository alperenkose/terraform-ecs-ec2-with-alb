
output "app_alb_domain" {
  description = "Auto assigned domain for the ALB"
  value       = module.alb.app_alb_domain
}

output "app_fqdn" {
  description = "FQDN pointing to the ALB for the application"
  value       = module.alb.app_fqdn
}
