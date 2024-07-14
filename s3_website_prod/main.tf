# Define an S3 bucket for hosting the static website
resource "aws_s3_bucket" "hosting_bucket" {
  bucket = var.bucket_name # Set the bucket name from a variable

  tags = {
    Name        = "Northwest website Prod" # Descriptive name for the bucket
    Environment = "Prod"                   # Environment tag to denote development stage
  }
}

# Configure the S3 bucket to serve a static website
resource "aws_s3_bucket_website_configuration" "hosting_bucket_configuration" {
  bucket = aws_s3_bucket.hosting_bucket.id # Reference to the hosting bucket

  index_document {
    suffix = "index.html" # Default document served by the website
  }

  error_document {
    key = "error.html" # Document served in case of an error
  }
}

# Enable versioning for the hosting bucket to keep a history of objects
resource "aws_s3_bucket_versioning" "hosting_bucket_versioning" {
  bucket = aws_s3_bucket.hosting_bucket.id
  versioning_configuration {
    status = "Enabled" # Enable versioning
  }
}

# Configure public access settings for the hosting bucket
resource "aws_s3_bucket_public_access_block" "hosting_bucket_block" {
  bucket = aws_s3_bucket.hosting_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false # These settings are configured to allow public access
}

# Set the access control list (ACL) for the hosting bucket to public-read
resource "aws_s3_bucket_acl" "hosting_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.hosting_bucket_controls,
    aws_s3_bucket_public_access_block.hosting_bucket_block,
  ]

  bucket = aws_s3_bucket.hosting_bucket.id
  acl    = "private" 
}

# Define ownership controls for the hosting bucket
resource "aws_s3_bucket_ownership_controls" "hosting_bucket_controls" {
  bucket = aws_s3_bucket.hosting_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred" # Set preferred ownership of objects
  }
}

# Define a bucket policy to allow public access to the website files
resource "aws_s3_bucket_policy" "hosting_bucket_policy" {
  bucket = aws_s3_bucket.hosting_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.hosting_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Output the URL of the hosted static website
output "website_url" {
  value = "http://${aws_s3_bucket.hosting_bucket.bucket}.s3-website-${var.aws_region}.amazonaws.com"
}