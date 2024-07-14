output "website_bucket_dev_url" {
  description = "URL of the dev website bucket"
  value       = data.aws_s3_bucket.website_bucket_dev.website_endpoint
}

output "website_bucket_prod_url" {
  description = "URL of the prod website bucket"
  value       = data.aws_s3_bucket.website_bucket_prod.website_endpoint
}

output "codebuild_webhook_url" {
  description = "URL of the CodeBuild test webhook"
  value       = aws_codebuild_webhook.webhook.url
}

output "codebuild_endpoint" {
  description = "URL of the CodeBuild test endpoint"
  value       = aws_codebuild_webhook.webhook.payload_url
}