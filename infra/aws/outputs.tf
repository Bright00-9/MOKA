output "api_url" {
  description = "Point PLATFORM_CALLBACK_URL and the Flutter app's API_BASE_URL at this (note: https, and includes your domain, not the raw ALB hostname)"
  value       = "https://${var.domain_name}"
}

output "alb_dns_name" {
  description = "Raw ALB hostname — useful for debugging DNS/cert issues before the Route 53 record propagates"
  value       = aws_lb.backend.dns_name
}

output "ecr_repository_url" {
  description = "docker tag/push the backend image here before the ECS service can start healthy"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.backend.name
}

output "rds_endpoint" {
  description = "Host:port for connecting a migration/seed run against the real RDS instance"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "aws_region" {
  value = var.aws_region
}

output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.backend.certificate_arn
}

