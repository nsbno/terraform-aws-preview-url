locals {
  service_name = "preview-url-mapper"

  # Mapping of environment to central deployment account ID
  central_deployment_account_id_mapping = {
    "prod"    = "433462727137"
    "test"    = "846274634169"
    "service" = "727832596008"
  }

  lambda_at_edge_artifact_bucket = "${local.central_deployment_account_id_mapping.service}-lambda-at-edge-preview-mapper"
  s3_artifact_path               = "${local.service_name}/main.zip"

  dynamodb_table_name = "platform-${local.service_name}"

  artifact = {
    store   = local.lambda_at_edge_artifact_bucket
    path    = local.s3_artifact_path
    version = data.aws_s3_object.latest_artifact.version_id
  }
}

resource "aws_ssm_parameter" "central_deployment_account_id" {
  # Current environment version of the lambda to use
  name = "/__deployment__/applications/${var.service_name}/central-deployment-account-id"
  type = "String"

  overwrite = true

  value = local.central_deployment_account_id_mapping[var.environment]
}

module "ssm_environment_version_permissions" {
  source = "github.com/nsbno/terraform-aws-service-permissions?ref=1.2.0"

  role_name = aws_iam_role.lambda_role.name

  ssm_parameters = [
    {
      arns        = [aws_ssm_parameter.central_deployment_account_id.arn]
      permissions = ["get"]
    }
  ]
}

data "aws_s3_object" "latest_artifact" {
  provider = aws.us_east_1

  bucket = local.lambda_at_edge_artifact_bucket
  key    = local.s3_artifact_path
}

# IAM Role for Lambda
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  provider = aws.us_east_1

  name               = "platform-${local.service_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# CloudWatch Logs Policy
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.lambda_log_group.arn,
      "${aws_cloudwatch_log_group.lambda_log_group.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  provider = aws.us_east_1

  name   = "lambda_logging"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_logging.json
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  provider = aws.us_east_1

  name              = "/aws/lambda/${local.service_name}"
  retention_in_days = 30
}

# Lambda Function
resource "aws_lambda_function" "lambda_function" {
  provider = aws.us_east_1

  function_name = local.service_name

  s3_bucket         = local.artifact.store
  s3_key            = local.artifact.path
  s3_object_version = local.artifact.version

  runtime = "python3.13"
  handler = "preview_url_mapper.handler.preview_url_handler"

  memory_size = 256
  timeout     = 30 # max allowed for Lambda@Edge

  role = aws_iam_role.lambda_role.arn

  publish = true

  lifecycle {
    ignore_changes = [
      qualified_arn,
      qualified_invoke_arn,
      version
    ]
  }
}

data "aws_lambda_function" "this" {
  # We use this data source to find the latest version of the Lambda
  # Encountered issues with the `publish` argument in the `aws_lambda_function` resource
  # Where it would update the Terraform code even without any code changes
  provider      = aws.us_east_1
  function_name = aws_lambda_function.lambda_function.function_name
}

module "centralized_ddb_mapping_permissions" {
  source = "github.com/nsbno/terraform-aws-service-permissions?ref=1.2.0"

  role_name = aws_iam_role.lambda_role.name

  dynamodb_tables = [
    {
      arns        = ["arn:aws:dynamodb:us-east-1:${local.central_deployment_account_id_mapping[var.environment]}:table/${local.dynamodb_table_name}"]
      permissions = ["put", "get", "delete"]
    }
  ]
}

# Service role for App Runner, for ephemeral App Runner tasks
resource "aws_iam_role" "app_runner_service_role" {
  provider = aws.us_east_1

  name = "${var.service_name}-app-runner-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_service_policy" {
  provider = aws.us_east_1

  role       = aws_iam_role.app_runner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role" "app_runner_instance_role" {
  provider = aws.us_east_1

  name = "${var.service_name}-app-runner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

# Used for App Runner tasks to access the DynamoDB table for session management.
# Useful if you want to share session state across multiple App Runner instances and the "real" ECS instances.
module "permissions_app_runner_instance_role" {
  source = "github.com/nsbno/terraform-aws-service-permissions?ref=1.2.0"

  count = var.dynamodb_sessions_table_arn != null ? 1 : 0

  role_name = aws_iam_role.app_runner_instance_role.name

  dynamodb_tables = [
    {
      arns        = [var.dynamodb_sessions_table_arn]
      permissions = ["get", "put", "delete"]
    }
  ]
}
