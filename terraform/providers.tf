terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state is environment-specific. Configure it with a partial backend:
  #   terraform init -backend-config=environments/dev.backend.hcl
  # backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
