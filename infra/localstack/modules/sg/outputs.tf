output "security_group_alb_id" {
  description = "The ID of the ALB ingress rule for the created security group."
  value       = aws_security_group_rule.alb.id
}

output "security_group_rds_id" {
  description = "The ID of the RDS ingress rule for the created security group."
  value       = aws_security_group_rule.rds.id
}