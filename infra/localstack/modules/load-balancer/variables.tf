variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
}

variable "security_group_alb_id" {
  description = "The ID of the ALB ingress rule for the created security group."
  type        = string
}

variable "security_group_rds_id" {
  description = "The ID of the RDS ingress rule for the created security group."
  type        = string
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of public subnet IDs for the ALB"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "VPC ID for the ALB and target group"
}

variable "backend_container_port" {
  type    = number
  default = 4000
}
