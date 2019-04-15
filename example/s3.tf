/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
module "example_team_s3_bucket" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=2.0"

  team_name              = "cloudplatform"
  business-unit          = "mojdigital"
  application            = "cloud-platform-terraform-s3-bucket"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "platform@digtal.justice.gov.uk"
  aws-s3-region          = "eu-west-2"
}

resource "kubernetes_secret" "example_team_s3_bucket" {
  metadata {
    name      = "example-team-s3-bucket-output"
    namespace = "my-namespace"
  }

  data {
    access_key_id     = "${module.example_team_s3_bucket.access_key_id}"
    secret_access_key = "${module.example_team_s3_bucket.secret_access_key}"
    bucket_arn        = "${module.example_team_s3_bucket.bucket_arn}"
    bucket_name       = "${module.example_team_s3_bucket.bucket_name}"
  }
}
