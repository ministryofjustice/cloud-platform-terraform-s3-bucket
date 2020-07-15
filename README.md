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
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=4.2"

  team_name              = "example-repo"
  acl                    = "public-read"
  versioning             =  true
  business-unit          = "example-bu"
  application            = "example-app"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "example-team@digtal.justice.gov.uk"

 /* 

  * Public Buckets: It is strongly advised to keep buckets 'private' and only make public where necessary. 
                    By default buckets are private, however to create a 'public' bucket add the following two variables when calling the module:

                    acl                           = "public-read"
                    enable_allow_block_pub_access = false

                    For more information granting public access to S3 buckets, please see AWS documentation: 
                    https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html

  * Converting existing private bucket to public: If amending an existing private bucket that was created using version 4.3 or above then you will need to raise two PRs:
                    
                    (1) First PR to add the var: enable_allow_block_pub_access = false
                    (2) Second PR to add the var: acl = "public-read"

  * Versioning: By default this is set to false. When set to true multiple versions of an object can be stored
                For more details on versioning please visit: https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html
  
  versioning             = true

  * Logging: By default set to false. When you enable logging, Amazon S3 delivers access logs for a source bucket to target            bucket that you choose.
             The target bucket must be in the same AWS Region as the source bucket and must not have a default retention period configuration.
             For more details on logging please vist: https://docs.aws.amazon.com/AmazonS3/latest/user-guide/server-access-logging.html

  logging_enabled        = true
  log_target_bucket      = "<TARGET_BUCKET_NAME>"
  log_path               = "<LOG_PATH>" e.g log/
  
*/

  # This is a new input.
  providers = {
    aws = aws.london
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
| logging_enabled | When set to true enables logging
| log_target_bucket | Target bucket where logs are to be delivered to
  log_path           | Path of logs on the target bucket e.g log/
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


### Source bucket policy

The source bucket must permit the destination s3 IAM user to "read" from its bucket explcitly.

Example to retrieve destination IAM user for use in source bucket policy. _requires [jq - commandline JSON processer](https://stedolan.github.io/jq/)_

```bash
# retrieve destination s3 user ARN

# retrieve live-1 namespace's s3 credentials
$ kubectl -n my-namespace get secret my-s3-secrets -o json | jq -r '.data[] | @base64d'
=>
<access_key_id>
<bucket_arn>
<bucket_name>
<secret_access_key>

# retrieve IAM user details using credentials
$ unset AWS_PROFILE; AWS_ACCESS_KEY_ID=<access_key_id> AWS_SECRET_ACCESS_KEY=<secret_access_key> aws sts get-caller-identity

# Alternative single call in bash
$ unset AWS_PROFILE; read K a n S <<<$(kubectl -n my-namespace get secret my-s3-secrets -o json | jq -r '.data[] | @base64d') ; AWS_ACCESS_KEY_ID=$K AWS_SECRET_ACCESS_KEY=$S aws sts get-caller-identity
```

You should get output similar to below:
```json
{
"UserId": "<userid>",
"Account": "<accountid>",
"Arn": "arn:aws:iam::<accountid>:user/system/s3-bucket-user/<team>/<random-s3-bucket-username>"
}
```

Example for the source bucket (using retrieved ARN from above):

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

Note the bucket being listed twice, this is needed not a typo - the first is for the bucket itself, second for objects within it.


### Destination IAM user policy
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

### Synchronization

Once configured the following, executed within a relevantly provisioned pod in the destination namespace, will add new, update existing and delete objects (not in source).

```bash
aws s3 sync --delete \
  s3://source_bucket_name \
  s3://destination_bucket_name \
  --source-region source_region \
  --region destination_region
```

For an example of a pod with a custom CLI that wraps s3 sync you can see the [cccd-migrator](https://github.com/ministryofjustice/cccd-migrator)



