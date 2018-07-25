# cloud-platform-terraform-s3-bucket module

Terraform module that will create an S3 bucket in AWS with relevant user account that will have access to bucket.

The bucket created will prefix the business unit tag and your team name to the bucket identifier to create the bucket name. This ensures that the bucket created is globally unique and avoids name clashes.

```bash
bucket name = ${business-unit}-${team_name}-${bucket_identifier}
```

## Usage

```hcl
module "example_team_s3" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=master"

  team_name         = "example-repo"
  bucket_identifier = "example-bucket"
  acl               = "public-read"
  versioning        =  true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl | acl manages access to your bucket | string | `private` | no |
| bucket_identifier | This is the bucket identifier, the bucket name will be this prefixed with your team name | string | - | yes |
| team_name |  | string | - | yes |
| versioning | version objects stored within your bucket. | boolean | false | no |

### Tags

Some of the inputs are tags. All infrastructure resources need to be tagged according to MOJ techincal guidence. The tags are stored as variables that you will need to fill out as part of your module.

https://ministryofjustice.github.io/technical-guidance/standards/documenting-infrastructure-owners/#documenting-owners-of-infrastructure

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application |  | string | - | yes |
| business-unit | Area of the MOJ responsible for the service | string | `mojdigital` | yes |
| environment-name |  | string | - | yes |
| infrastructure-support | The team responsible for managing the infrastructure. Should be of the form team-email | string | - | yes |
| is-production |  | string | `false` | yes |


## Outputs

| Name | Description |
|------|-------------|
| access_key_id | Access key id for s3 account |
| bucket_arn | Arn for s3 bucket created |
| bucket_name | bucket name |
| secret_access_key | Secret key for s3 account |
