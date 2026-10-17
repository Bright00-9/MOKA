output "ecr_repository_url" {
  description = "docker tag/push the backend image here before the ECS service can start healthy"
  value       = aws_ecr_repository.backend.repository_url
}
