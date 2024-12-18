terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Update to allow version 5.x
    }
  }

  required_version = ">= 0.12"
}