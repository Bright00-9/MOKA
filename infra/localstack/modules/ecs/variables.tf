variable "aws_region" {
  description = "AWS region (LocalStack accepts any valid region name)"
  type        = string
  default     = "us-east-1"
}


variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
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
  type    = number
  default = 1
}

variable "firebase_project_id" {
  type = string
}

variable "firebase_client_email" {
  type = string
}

variable "platform_callback_url" {
  type = string
}
