# cloud-platform-terraform-s3 module

Terraform module that will create an S3 bucket in AWS with relevant user account that will have access to bucket.

## Usage

```hcl
module "example_team_s3" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=master"

  team_name   = "example-repo"
  bucket_name = "example-bucket"
  acl         = "public"
  versioning  = "true"


}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl |  | string | `private` | no |
| bucket_name |  | string | - | yes |
| team_name |  | string | - | yes |
| versioning |  | string | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| access_key_id | Access keys id |
| bucket_arn | Arn for s3 bucket created |
| bucket_name | bucket name |
| iam_am_user | user name for s3 service account |
| policy_arn | ARN for the new policy |
| secret_access_key | Secret key for s3 account |
| user_arn | Arn for iam user |

