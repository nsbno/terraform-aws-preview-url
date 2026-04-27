data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ecs_execution" {
  name = "${var.service_name}-preview-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "allow_preview_to_access_ssm_parameters" {
  statement {
    effect = "Allow"
    sid = "AllowEcsServiceToAccessSsmParameters"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
    ]

    resources = [
      // Grant the ECS service access to the parameters that it owns and only those
      "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/__${var.service_name}__/*"
    ]
  }
}

resource "aws_iam_role_policy" "allow_preview_to_access_ssm_parameters" {
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.allow_preview_to_access_ssm_parameters.json
}



resource "aws_iam_role" "ecs_infrastructure" {
  name = "${var.service_name}-preview-ecs-infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure" {
  role       = aws_iam_role.ecs_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.service_name}-preview-ecs-task"
  description = "Role used by the running ECS service to get access to other AWS services"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}