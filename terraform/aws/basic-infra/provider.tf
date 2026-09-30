terraform {
  required_version = ">= 1.11.0"

  backend "s3" {
    bucket       = "devops-lab-tfstate-392362835269-us-east-1"
    key          = "basic-infra/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project = var.project_prefix
      env     = var.env_prefix
    }
  }
}