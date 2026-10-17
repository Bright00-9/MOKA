variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "moka"
}

variable "backend_container_port" {
  type    = number
  default = 4000
}
