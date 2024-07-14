terraform {
  required_version = "~> 1.7.0"
  required_providers {
    aws = {
      version = "~> 5.36.0"
    }
  }
  backend "s3" {
    bucket         = "hcw-terraform-state-87364"
    encrypt        = true
    dynamodb_table = "hcw-state-locks"
    key            = "pipeline/prod/terraform.tfstate"
    region         = "us-east-1"
    profile        = "temp"
  }
}
