provider "aws" {
    region = "us-west-2"
    profile = "rob-aws-account"
}

terraform {
  required_version = ">= 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34.0"
    }
  }

  backend "s3" {
    bucket  = "espn-fantasy-pred-tfstate"
    key     = "tfstate"
    region  = "us-west-2"
    profile = "rob-aws-account"
  }
}