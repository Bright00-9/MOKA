variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
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