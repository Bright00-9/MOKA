variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
}

variable "isolated_subnet_ids" {
  description = "List of isolated subnet IDs for the RDS instance"
  type        = list(string)
  default     = []
}

variable "security_group_rds_id" {
  description = "The ID of the RDS ingress rule for the created security group."
  type        = string
}

variable "db_name" {
  type    = string
  default = "moka"
}

variable "db_username" {
  type    = string
  default = "moka"
}

variable "db_password" {
  description = "RDS master password — pass via TF_VAR_db_password, never commit it"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}