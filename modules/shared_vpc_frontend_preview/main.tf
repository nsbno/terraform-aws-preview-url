data "aws_vpc" "shared" {
  tags = {
    Name = "shared"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }

  tags = {
    Tier = "Private"
  }
}

resource "aws_security_group" "frontend_preview" {
  name        = "${var.service_name}-frontend-preview"
  description = "Security group for ECS Express Service frontend preview deployments"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "App port from within VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ssm_parameter" "frontend_preview_security_group_id" {
  name  = "/config/${var.service_name}/frontend_preview_security_group_id"
  value = aws_security_group.frontend_preview.id
  type  = "String"
}

resource "aws_ssm_parameter" "frontend_preview_subnet_ids" {
  name      = "/config/shared/frontend_preview_subnet_ids"
  value     = join(",", data.aws_subnets.private.ids)
  type      = "String"
  overwrite = true
}
