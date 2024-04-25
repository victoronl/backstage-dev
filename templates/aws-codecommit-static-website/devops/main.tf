terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.44.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "static_website" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "static_website_acl" {
  bucket = aws_s3_bucket.static_website.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.static_website_ownership_controls]
}

resource "aws_s3_bucket_public_access_block" "static_website_access_block" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "static_website_ownership_controls" {
  bucket = aws_s3_bucket.static_website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket_public_access_block.static_website_access_block]
}

resource "aws_s3_bucket_website_configuration" "static_website_configuration" {
  bucket = aws_s3_bucket.static_website.id
  error_document {
    key = "404.html"
  }
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.static_website.arn}/*",
    }],
  })

  depends_on = [aws_s3_bucket_acl.static_website_acl]
}

resource "aws_s3_object" "static_site_index_document" {
  key          = "index.html"
  content      = "<html><body>Hello World!</body></html>"
  content_type = "text/html"
  bucket       = aws_s3_bucket.static_website.bucket

  depends_on = [aws_s3_bucket_policy.static_website_policy]
}

resource "aws_s3_object" "static_site_error_document" {
  key          = "404.html"
  content      = "<html><body>404!</body></html>"
  content_type = "text/html"
  bucket       = aws_s3_bucket.static_website.bucket

  depends_on = [aws_s3_bucket_policy.static_website_policy]
}

resource "aws_iam_policy" "static_website_codecommit_iam_policy" {
  name        = "${var.bucket_name}-codecommit-policy"
  description = "Policy for creating and managing CodeCommit repositories"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "codecommit:CreateRepository",
        "codecommit:DeleteRepository",
        "codecommit:GetRepository",
        "codecommit:ListRepositories",
        "codecommit:UpdateRepositoryDescription",
        "codecommit:UpdateRepositoryName",
      ],
      Resource = "*",
    }],
  })
}

resource "aws_iam_policy_attachment" "static_website_codecommit_attachment" {
  name       = "${var.bucket_name}-codecommit-policy-attachment"
  roles      = [aws_iam_role.static_website_codepipeline_role.name]
  policy_arn = aws_iam_policy.static_website_codecommit_iam_policy.arn
}

resource "aws_codecommit_repository" "static_website_codecommit_repository" {
  repository_name = aws_s3_bucket.static_website.bucket
}

resource "aws_iam_policy" "static_website_codepipeline_iam_policy" {
  name        = "${var.bucket_name}-codepipeline-policy"
  description = "Policy for CodePipeline to access resources"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject",
        "codecommit:Get*",
        "codecommit:GitPull",
        "codecommit:UploadArchive",
        "codecommit:CancelUploadArchive",
        "codecommit:CreateBranch",
        "codecommit:CreateCommit",
        "codecommit:CreatePullRequest",
        "codecommit:DeleteBranch",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:MergePullRequestByFastForward",
        "codecommit:TestRepositoryTriggers",
      ],
      Resource = [
        aws_s3_bucket.static_website.arn,
        "${aws_s3_bucket.static_website.arn}/*",
        aws_codecommit_repository.static_website_codecommit_repository.arn,
      ],
    }],
  })
}

resource "aws_iam_role" "static_website_codepipeline_role" {
  name = "${var.bucket_name}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com",
      },
      Action = "sts:AssumeRole",
    }],
  })

  inline_policy {
    name   = "${var.bucket_name}-codepipeline-inline-policy"
    policy = aws_iam_policy.static_website_codepipeline_iam_policy.policy
  }
}

resource "aws_codepipeline" "static_website_codepipeline" {
  name     = "${var.bucket_name}-static-website-pipeline"
  role_arn = aws_iam_role.static_website_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.static_website.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.static_website_codecommit_repository.repository_name
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        BucketName = aws_s3_bucket.static_website.bucket
        Extract    = "true"
      }
    }
  }
}
