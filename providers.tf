terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.25"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.34"
    }
  }
}

provider "cloudflare" {
  api_token  = var.cloudflare_api_token
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
