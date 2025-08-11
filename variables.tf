variable "environment" {
  description = "The environment for which central DynamoDB mapping to use"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["test", "prod"], var.environment)
    error_message = "The environment must be one of: test, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Only us-east-1 is allowed for this deployment."
  }
}

variable "service_name" {
  description = "The name of the service, should be same as the service name in the GHA Pipeline"
  type        = string
}
