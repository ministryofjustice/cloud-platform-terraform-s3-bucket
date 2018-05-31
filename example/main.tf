provider "aws" {
  region = "eu-west-1"
}

module "example_team_s3" {
  source = "../"

  team_name   = "example-repo"
  bucket_name = "example-bucket"
  acl         = "public"
  versioning  = "true"
}
