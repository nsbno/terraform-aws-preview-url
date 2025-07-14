output "lambda_function_qualifier_arn" {
  value = "${aws_lambda_function.lambda_function.arn}:${aws_lambda_alias.lambda_alias.function_version}"
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
