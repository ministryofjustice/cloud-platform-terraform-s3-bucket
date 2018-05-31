# example AWS S3 Creation

Configuration in this directory creates an example AWS public-read S3 bucket with versioning.

This example outputs user name and secrets for the new credentials.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Run `terraform destroy` when you want to destroy these resources created.

## Outputs

| Name | Description |
|------|-------------|
| access_key_id | Access key id for s3 account |
| bucket_arn | Arn for s3 bucket created |
| bucket_name | bucket name |
| iam_user_name | User name for s3 service account |
| policy_arn | ARN for the new policy |
| secret_access_key | Secret key for s3 account |
| user_arn | ARN for iam user |

