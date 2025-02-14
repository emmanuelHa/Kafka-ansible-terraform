terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.64"
    }
  }
  backend "s3" {
    bucket = "terraform-state-kafka-cluster-eha"
    key    = "global/s3/terraform.tfstate"
    region = "eu-west-3"
  }
}