# cloud-platform-terraform-s3-bucket module

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-terraform-s3-bucket/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-terraform-s3-bucket/releases)

Terraform module that will create an S3 bucket in AWS and a relevant user account that will have access to bucket.

The bucket created will have a randomised name of the format `cloud-platform-7a5c4a2a7e2134a`. This ensures that the bucket created is globally unique.

## Usage

**This module will create the resources in the region of the providers specified in the *providers* input.
Be sure to create the relevant providers, see example/main.tf
From module version 3.2, this replaces the use of the `aws-s3-region`.**

```hcl
module "example_team_s3" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket"

  team_name              = "example-repo"
  acl                    = "public-read"
  versioning             =  true
  business-unit          = "example-bu"
  application            = "example-app"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "example-team@digtal.justice.gov.uk"

  # This is a new input.
  providers = {
    aws = "aws.london"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl | acl manages access to your bucket | string | `private` | no |
| bucket_policy | The S3 bucket policy to set. If empty, no policy will be set | string | `""` | no |
| user_policy | The IAM policy to assign to the generated user. If empty, the default policy is used | string | `""` | no |
| versioning | version objects stored within your bucket. | boolean | `false` | no |
| providers | provider to use | array of string | default provider | no

### Tags

Some of the inputs are tags. All infrastructure resources need to be tagged according to the [MOJ techincal guidence](https://ministryofjustice.github.io/technical-guidance/standards/documenting-infrastructure-owners/#documenting-owners-of-infrastructure). The tags are stored as variables that you will need to fill out as part of your module.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application |  | string | - | yes |
| business-unit | Area of the MOJ responsible for the service | string | `mojdigital` | yes |
| environment-name |  | string | - | yes |
| infrastructure-support | The team responsible for managing the infrastructure. Should be of the form team-email | string | - | yes |
| is-production |  | string | `false` | yes |
| team_name |  | string | - | yes |


## Outputs

| Name | Description |
|------|-------------|
| access_key_id | Access key id for s3 account |
| bucket_arn | Arn for s3 bucket created |
| bucket_name | bucket name |
| secret_access_key | Secret key for s3 account |

## Migrate from existing buckets

The `user_policy` input is useful when migrating data from existing bucket(s). For commands like `s3 ls` or `s3 sync` to work across accounts, a policy granting access must be set in 2 places: the *source bucket* and the *destination user*

Example for the source bucket:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowSourceBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Principal": {
                "AWS": "arn:aws:iam::<accountid>:user/system/s3-bucket-user/<team>/s3-bucket-user-random"
            },
            "Resource": [
                "arn:aws:s3:::source-bucket",
                "arn:aws:s3:::source-bucket/*"
            ]
        }
    ]
}
```

Note the bucket being listed twice, this is needed not a typo.

Example for the destination IAM user created by this module:

```
  user_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Sid": "",
    "Effect": "Allow",
    "Action": [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ],
    "Resource": [
      "$${bucket_arn}",
      "arn:aws:s3:::source-bucket"
    ]
  },
  {
    "Sid": "",
    "Effect": "Allow",
    "Action": [
      "s3:*"
    ],
    "Resource": [
      "$${bucket_arn}/*",
      "arn:aws:s3:::source-bucket/*"
    ]
  }
]
}
EOF
```
