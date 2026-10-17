variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
}

# App secrets — all pushed into Secrets Manager and injected into the ECS task
# as `secrets` (not plain env vars), matching how env.ts expects them.
variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "paystack_secret_key" {
  type      = string
  sensitive = true
}

variable "paystack_webhook_secret" {
  type      = string
  sensitive = true
}

variable "firebase_private_key" {
  type      = string
  sensitive = true
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
