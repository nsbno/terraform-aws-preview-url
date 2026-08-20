data "aws_vpc" "shared" {
  tags = {
    Name = "shared"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }

  tags = {
    Tier = "Public"
  }
}

resource "aws_security_group" "frontend_preview" {
  name        = "${var.service_name}-frontend-preview"
  description = "Security group for ECS Express Service frontend preview deployments"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "All traffic from within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  name  = "/__deployment__/${var.service_name}/frontend_preview_security_group_id"
  value = aws_security_group.frontend_preview.id
  type  = "String"
}

resource "aws_ssm_parameter" "frontend_preview_subnet_ids" {
  name      = "/__deployment__/${var.service_name}/frontend_preview_subnet_ids"
  value     = join(",", data.aws_subnets.public.ids)
  type      = "String"
  overwrite = true
}

