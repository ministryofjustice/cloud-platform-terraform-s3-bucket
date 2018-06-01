# cloud-platform-terraform-s3-bucket module

Terraform module that will create an S3 bucket in AWS with relevant user account that will have access to bucket.

The bucket created will use ${team_name}-${bucket_identifier} as the bucket name to ensure that the bucket created is globally unique and avoid name clashes.

## Usage

```hcl
module "example_team_s3" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=master"

  team_name         = "example-repo"
  bucket_identifier = "example-bucket"
  acl               = "public-read"
  versioning        = "true"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl | acl manages access to your bucket | string | `private` | no |
| bucket_identifier | This is the bucket identifier, the bucket name will be this prefixed with your team name | string | - | yes |
| team_name |  | string | - | yes |
| versioning | version objects stored within your bucket. | string | `false` | no |

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

## tags 

All infrastructure resources need to be tagged according to MOJ techincal guidence. The tags are stored as variables that you will need to fill out as part of your module.
https://ministryofjustice.github.io/technical-guidance/standards/documenting-infrastructure-owners/#documenting-owners-of-infrastructure

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application |  | string | - | yes |
| business-unit |  | string | - | yes |
| component |  | string | - | yes |
| environment-name |  | string | - | yes |
| infrastructure-support |  | string | - | yes |
| is-production |  | string | `false` | no |
| owner |  | string | - | yes |
| runbook |  | string | - | yes |
| source-code |  | string | - | yes |





