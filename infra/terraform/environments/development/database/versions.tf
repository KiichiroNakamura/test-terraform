terraform {
  required_version = "1.3.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }

  backend "s3" {
    region = "ap-northeast-1"
    bucket = "terraform-bgl-bsd9999-dev"
    key    = "mobile-call-history/database/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
