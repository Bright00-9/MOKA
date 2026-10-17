output "rds_endpoint" {
  description = "Host:port for connecting a migration/seed run against the real RDS instance"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_address" {
  description = "Host for connecting a migration/seed run against the real RDS instance"
  value       = aws_db_instance.main.address
  sensitive   = true
}