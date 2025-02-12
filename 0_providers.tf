terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.85.0"
    }
  }

  backend "s3" {
    bucket = "prerequisites-eks-dynatrace-infra"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Name        = "eks_dynatrace"
      Purpose     = "infrastructure for setting up eks w/ dynatrace"
      Environment = "dev"
    }
  }
}
