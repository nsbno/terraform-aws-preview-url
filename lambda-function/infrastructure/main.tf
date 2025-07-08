locals {
  service_name = "preview-url-mapper"
}

data "vy_artifact_version" "this" {
  application = local.service_name
}

module "lambda" {
  source = "github.com/nsbno/terraform-aws-lambda?ref=codedeploy"

  providers = {
    aws = aws.us-east-1
  }

  service_name = local.service_name

  artifact      = data.vy_artifact_version.this
  artifact_type = "s3"

  handler = "get_preview_url_by_domain"
  runtime = "python3.13"

  memory = 256
}

data "aws_organizations_organization" "this" {}

resource "aws_lambda_permission" "allow_org_invoke" {
  statement_id  = "AllowOrgInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "*"
  qualifier     = module.lambda.function_qualifier

  condition {
    test     = "StringEquals"
    variable = "aws:PrincipalOrgID"
    values   = [data.aws_organizations_organization.this.id]
  }
}

module "dynamodb" {
  source = "github.com/nsbno/terraform-aws-dynamodb?ref=1.0.3"

  providers = {
    aws = aws.us-east-1
  }

  table_name = "${local.service_name}-table"
  hash_key   = "domain"

  ttl_enabled   = true
  ttl_attribute = "timestamp"
}

module "permissions" {
  source = "github.com/nsbno/terraform-aws-service-permissions?ref=1.2.0"

  role_name = module.lambda.role_name

  dynamodb_tables = [
    {
      arns        = [module.dynamodb.arn]
      permissions = ["put", "get", "delete"]
    }
  ]
}
