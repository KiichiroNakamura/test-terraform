terraform {
  required_version = "1.3.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }

  backend "s3" {
    region = "ap-northeast-1"
    bucket = "terraform-bgl-bsd3317-prd"
    key    = "mobile-call-history/monitoring/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
