provider "aws" {
  region  = "us-west-2"
  profile = "rob-aws-account"
}

terraform {
  backend "s3" {
    bucket  = "espn-fantasy-pred-tfstate"
    key     = "tfstate"
    region  = "us-west-2"
    profile = "rob-aws-account"
  }
}