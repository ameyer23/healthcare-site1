variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the bucket"
  type        = string
  default     = "hcw-website-bucket-prod-2024"
}

# For these variable code to work, Add terraform.tfvars file and place only the variable value in it.
variable "aws_profile" {
  description = "Name of the AWS Profile being used"
  type        = string
}
