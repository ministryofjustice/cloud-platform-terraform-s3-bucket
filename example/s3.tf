/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
# module "example_team_s3_bucket" {
#   source = ".."

#   team_name              = "cloudplatform"
#   business-unit          = "mojdigital"
#   application            = "cloud-platform-terraform-s3-bucket"
#   is-production          = "false"
#   environment-name       = "development"
#   infrastructure-support = "platform@digtal.justice.gov.uk"
#   aws-s3-region          = "eu-west-2"

#   providers = {
#     aws = "aws.module"
#   }

  /*
   * The following are exampls of bucket and user policies. They are treated as
   * templates. Currently, the only available variable is `$${bucket_arn}`.
   *
   */

  /*
 * Allow a user (foobar) from another account (012345678901) to get objects from
 * this bucket.
 *

   bucket_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::012345678901:user/foobar"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "$${bucket_arn}/*"
      ]
    }
  ]
}
EOF

*/

  /*
 * Override the default policy for the generated machine user of this bucket.
 *

user_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Sid": "",
    "Effect": "Allow",
    "Action": [
      "s3:GetBucketLocation"
    ],
    "Resource": "$${bucket_arn}"
  },
  {
    "Sid": "",
    "Effect": "Allow",
    "Action": [
      "s3:GetObject"
    ],
    "Resource": "$${bucket_arn}/*"
  }
]
}
EOF

*/
# }
