terraform {
  backend "s3" {
    key        = "preview-url-mapper/main.tfstate"
    bucket     = "846274634169-terraform-state"
    acl        = "bucket-owner-full-control"
    encrypt    = "true"
    kms_key_id = "arn:aws:kms:eu-west-1:846274634169:alias/846274634169-terraform-state-encryption-key"
    region     = "eu-west-1"
  }
}

module "this" {
  source = "../../infrastructure"

  environment = "test"
}
