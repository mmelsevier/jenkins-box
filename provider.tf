terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.11.0"
    }
  }

  backend "s3" {
    bucket = "terraform-backends-mm"
    key    = "jenkins-box"
    region = "eu-west-2"
  }
}

provider "aws" {
  region = var.region
}
