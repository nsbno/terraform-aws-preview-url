terraform {
  backend "s3" {
	key            = "preview-url-mapper/main.tfstate"
	bucket         = "727832596008-terraform-state"
	acl            = "bucket-owner-full-control"
	encrypt        = "true"
	kms_key_id     = "arn:aws:kms:eu-west-1:727832596008:alias/727832596008-terraform-state-encryption-key"
	region         = "eu-west-1"
  }
}

locals {
  test_account_id    = "846274634169"
  stage_account_id   = "974021908697"
  prod_account_id    = "433462727137"
  service_account_id = "727832596008"
}

resource "aws_s3_bucket" "this" {
  region = "us-east-1" # Required for Lambda@Edge artifacts

  bucket = "${local.service_account_id}-lambda-at-edge-artifacts"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "allow_account_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [local.test_account_id, local.stage_account_id, local.prod_account_id, local.service_account_id]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_account_access" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_account_access.json
}
