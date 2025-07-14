terraform {
  backend "s3" {
    key        = "preview-url-mapper/main.tfstate"
    bucket     = "727832596008-terraform-state"
    acl        = "bucket-owner-full-control"
    encrypt    = "true"
    kms_key_id = "arn:aws:kms:eu-west-1:727832596008:alias/727832596008-terraform-state-encryption-key"
    region     = "eu-west-1"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}

provider "aws" {
  region              = "us-east-1" # This is the required region for Lambda@Edge
  allowed_account_ids = ["727832596008"]
}

locals {
  service_account_id = "727832596008"
}

# LAMBDA@EDGE ARTIFACTS
resource "aws_s3_bucket" "this" {
  bucket = "${local.service_account_id}-lambda-at-edge-preview-mapper"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_organizations_organization" "this" {}

data "aws_iam_policy_document" "allow_account_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.this.id]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_account_access" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_account_access.json
}
