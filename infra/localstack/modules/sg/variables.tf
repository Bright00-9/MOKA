variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
}

variable "vpc_id" {
  description = "VPC ID where the security groups will be created"
  type        = string
}

variable "backend_container_port" {
  type    = number
  default = 4000
}

variable "rds_port" {
  type    = number
  default = 5432
}
