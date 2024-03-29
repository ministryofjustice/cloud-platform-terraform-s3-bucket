# cloud-platform-terraform-s3-bucket

[![Releases](https://img.shields.io/github/v/release/ministryofjustice/cloud-platform-terraform-s3-bucket.svg)](https://github.com/ministryofjustice/cloud-platform-terraform-s3-bucket/releases)

This Terraform module will create an [Amazon S3](https://aws.amazon.com/s3/) bucket for use on the Cloud Platform.

## Usage

```hcl
module "s3" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=version" # use the latest release

  # S3 configuration
  versioning = true

  # Tags
  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name
  namespace              = var.namespace
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}
```

### Migrate from existing buckets

<!-- TODO: Needs rewriting after removal of access keys. -->

The `user_policy` input is useful when migrating data from existing bucket(s). For commands like `s3 ls` or `s3 sync` to work across accounts, a policy granting access must be set in 2 places: the *source bucket* and the *destination user*


#### Source bucket policy

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

#### Destination IAM user policy
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

#### Synchronization

Once configured the following, executed within a relevantly provisioned pod in the destination namespace, will add new, update existing and delete objects (not in source).

```bash
aws s3 sync --delete \
  s3://source_bucket_name \
  s3://destination_bucket_name \
  --source-region source_region \
  --region destination_region
```

For an example of a pod with a custom CLI that wraps s3 sync you can see the [cccd-migrator](https://github.com/ministryofjustice/cccd-migrator)

#### Decompressing Files Stored in S3

If you have some files stored in S3 that are compresses (e.g. `.zip`, `.gzip`, `.bz2`, `.p7z`) you don't need to fully download and re-upload them in order to decompress them you can quite easily decompress them on the cloud platform kubernetes cluster with a `Job`.

The following example, is a `Job` pod connected to a 50Gb persistent volume (so any temporary storage does not fill up a cluster node), using `bunzip2` to decompress a `.bz2` file and re-upload it to S3.

For your needs, simply substitute the namespace, AWS creds, the bucket/filename and the compression tool, then you should be able to use this to decompress a file of any size without having to download them locally to your machine.

```yaml
---
apiVersion: batch/v1
kind: Job
metadata:
  name: s3-decompression
  namespace: default
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: tools
          image: ministryofjustice/cloud-platform-tools:1.43
          command:
            - /bin/bash
            - -c
            - |
              cd /unpack
              aws s3 cp s3://${S3_BUCKET}/<filename>.bz2 - \
                | bunzip2 \
                | aws s3 cp - s3://${S3_BUCKET}/<filename>
          env:
            - name: AWS_ACCESS_KEY_ID
              value: <aws-access-key-id>
            - name: AWS_SECRET_ACCESS_KEY
              value: <aws-secret-access-key>
            - name: S3_BUCKET
              value: <s3-bucket-name>
          resources: {}
          volumeMounts:
            - name: unpack
              mountPath: "/unpack"
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            runAsGroup: 1000
      volumes:
        - name: unpack
          persistentVolumeClaim:
            claimName: unpack-small

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: unpack-small
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: "gp2-expand"
  resources:
    requests:
      storage: 50Gi
```

See the [examples/](examples/) folder for more information.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.block_public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_iam_policy_document.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acl"></a> [acl](#input\_acl) | The bucket ACL to set | `string` | `"private"` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Set the name of the S3 bucket. If left blank, a name will be automatically generated (recommended) | `string` | `""` | no |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | The S3 bucket policy to set. If empty, no policy will be set | `string` | `""` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | Area of the MOJ responsible for the service | `string` | n/a | yes |
| <a name="input_cors_rule"></a> [cors\_rule](#input\_cors\_rule) | cors rule | `any` | `[]` | no |
| <a name="input_enable_allow_block_pub_access"></a> [enable\_allow\_block\_pub\_access](#input\_enable\_allow\_block\_pub\_access) | Enable whether to allow for the bucket to be blocked from public access | `bool` | `true` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name | `string` | n/a | yes |
| <a name="input_infrastructure_support"></a> [infrastructure\_support](#input\_infrastructure\_support) | The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>) | `string` | n/a | yes |
| <a name="input_is_production"></a> [is\_production](#input\_is\_production) | Whether this is used for production or not | `string` | n/a | yes |
| <a name="input_lifecycle_rule"></a> [lifecycle\_rule](#input\_lifecycle\_rule) | lifecycle | `any` | `[]` | no |
| <a name="input_log_path"></a> [log\_path](#input\_log\_path) | Set the path of the logs | `string` | `""` | no |
| <a name="input_log_target_bucket"></a> [log\_target\_bucket](#input\_log\_target\_bucket) | Set the target bucket for logs | `string` | `""` | no |
| <a name="input_logging_enabled"></a> [logging\_enabled](#input\_logging\_enabled) | Set the logging for bucket | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace name | `string` | n/a | yes |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | Team name | `string` | n/a | yes |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Enable object versioning for the bucket | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | S3 bucket ARN |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Regional bucket domain name |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | S3 bucket name |
| <a name="output_irsa_policy_arn"></a> [irsa\_policy\_arn](#output\_irsa\_policy\_arn) | IAM policy ARN for access to the S3 bucket |
<!-- END_TF_DOCS -->

## Tags

Some of the inputs for this module are tags. All infrastructure resources must be tagged to meet the MOJ Technical Guidance on [Documenting owners of infrastructure](https://technical-guidance.service.justice.gov.uk/documentation/standards/documenting-infrastructure-owners.html).

You should use your namespace variables to populate these. See the [Usage](#usage) section for more information.

## Reading Material

- [Cloud Platform user guide](https://user-guide.cloud-platform.service.justice.gov.uk/#cloud-platform-user-guide)
- [Amazon S3 user guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
