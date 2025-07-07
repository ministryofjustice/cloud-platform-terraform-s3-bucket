terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "eu-west-2"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

module "s3" {
  source = "../.."

  team_name              = "cloud-platform"
  business_unit          = "mojdigital"
  application            = "cloud-platform-terraform-s3-bucket"
  is_production          = "false"
  environment_name       = "development"
  infrastructure_support = "platform@digtal.justice.gov.uk"
  namespace              = "cloud-platform"
}

module "s3_with_oidc" {
  source = "../.."

  team_name              = "cloud-platform"
  business_unit          = "mojdigital"
  application            = "cloud-platform-terraform-s3-bucket"
  is_production          = "false"
  environment_name       = "development"
  infrastructure_support = "platform@digtal.justice.gov.uk"
  namespace              = "cloud-platform"

  oidc_providers = ["github"]
}
