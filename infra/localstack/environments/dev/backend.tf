terraform {
  required_version = "1.3.0"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "moka-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "moka-terraform-locks"
    encryption    = true
  }
}

