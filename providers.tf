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

    sendgrid = {
      source  = "taharah/sendgrid"
      version = "0.2.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "sendgrid" {
  api_key = var.sendgrid_api_key
}
