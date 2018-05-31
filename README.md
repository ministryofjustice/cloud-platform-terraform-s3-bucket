# cloud-platform-terraform-s3 module

Terraform module that will create an S3 bucket in AWS with relevant user account that will have access to bucket.

The bucket created will use $team_name-$bucket_identifier as the bucket name to ensure the bucket created is globally unique and avoid name clashes with buckets.

## Usage

```hcl
module "example_team_s3" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=master"

  team_name   = "example-repo"
  bucket_name = "example-bucket"
  acl         = "public-read"
  versioning  = "true"


}
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl |  | string | `private` | no |
| bucket_identifier |  | string | - | yes |
| team_name |  | string | - | yes |
| versioning |  | string | `false` | no |

canned acl = https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
versioning = https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html

## Outputs

| Name | Description |
|------|-------------|
| access_key_id | Access key id for s3 account |
| bucket_arn | Arn for s3 bucket created |
| bucket_name | bucket name |
| iam_user_name | user name for s3 service account |
| policy_arn | ARN for the new policy |
| secret_access_key | Secret key for s3 account |
| user_arn | Arn for iam user |

