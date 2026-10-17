variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use. Leave empty to fall back to the default credential chain."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "azs" {
  description = "Availability zones for the two-subnet-per-tier layout"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "backend_image" {
  description = "Full image URI (ECR repo URL + tag) for the backend container"
  type        = string
  default     = "moka-backend:latest" # overridden after the ECR repo is created — see README
}

variable "backend_container_port" {
  type    = number
  default = 4000
}

variable "backend_cpu" {
  description = "Fargate task CPU units (256 = .25 vCPU)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "2+ so a single AZ or task failure doesn't take the API down — the tradeoff LocalStack's build skips for local iteration speed."
  type        = number
  default     = 2
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

variable "db_multi_az" {
  description = "Standby replica in a second AZ. Real HA posture — costs roughly 2x the single-AZ instance price."
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Must be false for anything holding real data — `terraform destroy` takes a final snapshot instead of silently dropping the database."
  type        = bool
  default     = false
}

variable "db_final_snapshot_identifier" {
  description = "Name for the snapshot `terraform destroy` takes (only used when db_skip_final_snapshot = false)"
  type        = string
  default     = "moka-db-final"
}

# --- HTTPS / domain — the real-AWS build terminates TLS at the ALB ---

variable "domain_name" {
  description = "Fully-qualified domain the API will be reachable at, e.g. api.moka.example.com. Must live in the Route 53 zone given by hosted_zone_id."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID that already owns domain_name's parent domain (create the zone once, by hand, before running this)"
  type        = string
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

variable "firebase_project_id" {
  type = string
}

variable "firebase_client_email" {
  type = string
}

variable "firebase_private_key" {
  type      = string
  sensitive = true
}

variable "platform_callback_url" {
  type = string
}
