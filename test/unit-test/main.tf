terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "eu-west-2"
}

module "s3" {
  source = "../.."

  team_name              = "cloud-platform"
  business-unit          = "mojdigital"
  application            = "cloud-platform-terraform-s3-bucket"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "platform@digtal.justice.gov.uk"
  namespace              = "cloud-platform"
}

