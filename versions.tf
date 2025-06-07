terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }

  # Backend configured via -backend-config flag for multi-environment support
  backend "s3" {}
}
