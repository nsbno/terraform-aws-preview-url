terraform {
  required_version = "1.12.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    vy = {
      source  = "nsbno/vy"
      version = ">= 0.3.1, < 0.4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # lambda@edge

  default_tags {
    tags = {
      application = "preview-url-mapper"
    }
  }
}

provider "vy" {
  environment = var.environment
}
