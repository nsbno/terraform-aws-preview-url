output "lambda_function_qualifier_arn" {
  value = "${aws_lambda_function.lambda_function.arn}:${data.aws_lambda_function.this.version}"
}

output "lambda_function_name" {
  value = aws_lambda_function.lambda_function.function_name
}

output "lambda_role_name" {
  value = aws_iam_role.lambda_role.name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "preview_instance_iam_role_name" {
  value = aws_iam_role.app_runner_instance_role.name
}
