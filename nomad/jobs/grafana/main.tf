terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
  backend "s3" {
    bucket = "soleks-terraform-states"
    key = "states/kraker-mysql"
    region = "us-west-2"
    profile = "default"
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region = "us-west-2"
}
