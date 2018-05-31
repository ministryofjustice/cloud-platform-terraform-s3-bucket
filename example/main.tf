provider "aws" {
  region = "eu-west-1"
}

module "example_team_s3" {
  source = "../"

  team_name         = "example-repo"
  bucket_identifier = "example-bucket"
  acl               = "public-read"
  versioning        = "true"
}
