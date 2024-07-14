#####################################
# Provider
#####################################

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

#####################################
# Data Sources
#####################################

data "aws_s3_bucket" "website_bucket_dev" {
  bucket = var.bucket_name_website_dev
}
data "aws_s3_bucket" "website_bucket_prod" {
  bucket = var.bucket_name_website_prod
}

#####################################
# Artifact Store
#####################################

resource "aws_s3_bucket" "artifact_store" {
  bucket        = "${var.bucket_prefix_artifacts}-${var.environment}-${var.bucket_suffix_artifacts}"
  force_destroy = true

}

resource "aws_s3_bucket_lifecycle_configuration" "artifact_store_lifecycle" {
  bucket = aws_s3_bucket.artifact_store.id
  rule {
    id     = "expire_artifacts"
    status = "Enabled"
    expiration {
      days = 1
    }

  }
}

resource "aws_s3_bucket_ownership_controls" "artifact_store_controls" {
  bucket = aws_s3_bucket.artifact_store.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "artifact_store_versioning" {
  bucket = aws_s3_bucket.artifact_store.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "artifact_store_policy" {
  bucket = aws_s3_bucket.artifact_store.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "SSEAndSSLPolicy",
    "Statement" : [
      {
        "Sid" : "DenyUnEncryptedObjectUploads",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.artifact_store.id}/*",
        "Condition" : {
          "StringNotEquals" : {
            "s3:x-amz-server-side-encryption" : "aws:kms"
          }
        }
      },
      {
        "Sid" : "DenyInsecureConnections",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.artifact_store.id}/*",
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}

#####################################
# Pipeline
#####################################

# Configuration works, but a manual connection is required at https://console.aws.amazon.com/codesuite/settings/connections
# Once connection to repository is made, the connection ARN needs to be inserted into line 41 of variables.tf
# Also need to figure out how to filter files and triggers

# Pipeline runs on merged pull requests

resource "aws_codepipeline" "pipeline" {
  name          = "${var.project}-pipeline-${var.environment}"
  role_arn      = var.codepipeline_role
  pipeline_type = var.pipeline_type

  artifact_store {
    location = aws_s3_bucket.artifact_store.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.connection_arn
        FullRepositoryId = "${var.github_owner}/${var.repository}"
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  # This stage extracts the index.html file from the source code
  stage {
    name = "Filter"

    action {
      name             = "Filter"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["filter_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.filter.name
      }
    }
  }
  stage {
    name = "Deploy_to_Dev_Bucket"

    action {
      name            = "Deploy_to_Dev_Bucket"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["filter_output"]
      version         = "1"

      configuration = {
        BucketName = var.bucket_name_website_dev
        Extract    = "true"
      }
    }
  }
  stage {
    name = "Manual_Approval"

    action {
      name     = "Manual_Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"


      configuration = {
        CustomData         = "Approve the deployment of the website to the production bucket"
        ExternalEntityLink = data.aws_s3_bucket.website_bucket_dev.website_endpoint
      }
    }
  }
  stage {
    name = "Deploy_to_Prod_Bucket"

    action {
      name            = "Deploy_to_Prod_Bucket"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["filter_output"]
      version         = "1"

      configuration = {
        BucketName = var.bucket_name_website_prod
        Extract    = "true"
      }
    }
  }
}

############################################
# CodeBuild Projects
############################################

# This CodeBuild project runs on pull requests and reports status checks to GitHub
resource "aws_codebuild_project" "test" {
  name          = "${var.project}-test-build-step-${var.environment}"
  description   = "Run unit test to deterimine Title exists on index.html"
  build_timeout = 5
  service_role  = var.codebuild_role
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type                = "GITHUB"
    buildspec           = "CI_Pipeline/files/test_buildspec.yml"
    location            = "https://github.com/${var.github_owner}/${var.repository}.git"
    report_build_status = true
    build_status_config {
      context = "Check index.html for Title"
    }

  }
  artifacts {
    type = "NO_ARTIFACTS"
    name = null
  }
  cache {
    type = "NO_CACHE"
  }
}

resource "aws_codebuild_webhook" "webhook" {
  project_name = aws_codebuild_project.test.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "BASE_REF"
      pattern = "refs/heads/${var.github_branch}"
    }
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED"
    }
  }
  filter_group {
    filter {
      type    = "BASE_REF"
      pattern = "refs/heads/${var.github_branch}"
    }
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_UPDATED"
    }
  }
  filter_group {
    filter {
      type    = "BASE_REF"
      pattern = "refs/heads/${var.github_branch}"
    }
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_REOPENED"
    }
  }
}

resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}


resource "aws_codebuild_project" "filter" {
  name          = "${var.project}-filter-build-step-${var.environment}"
  description   = "Filter out index.html"
  service_role  = var.codebuild_role
  build_timeout = "5"
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type                = "CODEPIPELINE"
    buildspec           = "CI_Pipeline/files/filter_buildspec.yml"
  }
  artifacts {
    type = "CODEPIPELINE"

  }
  cache {
    type = "NO_CACHE"
  }
}
