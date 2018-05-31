provider "aws" {
  region = "eu-west-1"
}

module "example_team_s3" {
  source = "../"

  team_name         = "example-repo"
  bucket_identifier = "example-bucket"
  acl               = "public-read"
  versioning        = "true"

  business-unit          = "MOJdigital"
  application            = "cloud-platform-terraform-s3"
  component              = "Storage"
  is-production          = "false"
  environment-name       = "development"
  owner                  = "cloudplatform"
  infrastructure-support = "platforms@digital.justice.gov.uk"
  runbook                = "opsmanual.dsd.io"
  source-code            = "https://github.com/ministryofjustice/cloud-platform-terraform-s3-bucket"
}
