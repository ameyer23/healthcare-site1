terraform {
   backend "s3" {
    bucket         = "hcw-terraform-state-87364"
    encrypt        = true
    dynamodb_table = "hcw-state-locks"
    key            = "website_bucket_prod/terraform.tfstate" 
    region         = "us-east-1"
    
   }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}