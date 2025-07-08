locals {
  service_name = "preview-url-mapper"

  lambda_at_edge_artifact_bucket = "727832596008-lambda-at-edge-artifacts"
  s3_artifact_path = "${local.service_name}/main.zip"

  artifact = {
	store = local.lambda_at_edge_artifact_bucket
	path    = local.s3_artifact_path
	version = data.aws_s3_object.latest_artifact.version_id
  }
}

data "aws_s3_object" "latest_artifact" {
  bucket = local.lambda_at_edge_artifact_bucket
  key    = local.s3_artifact_path
}

module "lambda" {
  source = "github.com/nsbno/terraform-aws-lambda?ref=codedeploy"

  service_name = local.service_name

  artifact      = local.artifact
  artifact_type = "s3"

  # Name correspond to built artifact
  handler = "preview_url_mapper.handler.get_preview_url_by_domain"
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

  principal_org_id = data.aws_organizations_organization.this.id
}

module "dynamodb" {
  source = "github.com/nsbno/terraform-aws-dynamodb?ref=1.0.3"

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
