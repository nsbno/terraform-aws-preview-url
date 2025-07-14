locals {
  service_name = "preview-url-mapper"
}

module "dynamodb" {
  source = "github.com/nsbno/terraform-aws-dynamodb?ref=1.0.3"

  table_name = "platform-${local.service_name}"
  hash_key   = "domain"

  ttl_enabled   = true
  ttl_attribute = "timestamp"
}

data "aws_organizations_organization" "this" {}

data "aws_iam_policy_document" "org_access" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]

    resources = [
      module.dynamodb.arn,
      "${module.dynamodb.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.this.id]
    }
  }
}

resource "aws_dynamodb_resource_policy" "org_access" {
  resource_arn = module.dynamodb.arn
  policy       = data.aws_iam_policy_document.org_access.json
}
