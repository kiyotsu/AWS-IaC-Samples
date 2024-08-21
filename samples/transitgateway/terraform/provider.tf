terraform {
  required_version = ">= 1.8.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.58.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project = "Security"
      Env     = "Prod"
    }
  }
}