terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Local state is fine while you're the only one applying this. If you start
  # sharing it (or just want state that survives a wiped laptop), switch to
  # an S3 backend + DynamoDB lock table — that's a good next AWS-service
  # exercise in its own right. Left as a plain local backend for now so this
  # directory works with zero extra setup.
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "moka/aws/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "your-tflock-table"
  #   encrypt        = true
  # }
}
