variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
}

variable "environment" {
  description = "The environment for the current deploy"
  type        = string
}

variable "vpc_cidr" {
  type    = string
}

variable "az_count" {
  description = "Number of availability zones to use for the two-subnet-per-tier layout"
  type        = number
  default     = 2
}