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

You can use a combination of the [Cloud Platform IRSA module](https://github.com/ministryofjustice/cloud-platform-terraform-irsa) and [Service pod module](https://github.com/ministryofjustice/cloud-platform-terraform-service-pod) to access your source bucket using the AWS CLI.

#### IRSA and Service Pod example configuration

In the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments) repository, within your namespace which contains your destination s3 bucket configuration, add the following terraform, substituting values as necessary:

```
module "cross_irsa" {
  source                 = "github.com/ministryofjustice/cloud-platform-terraform-irsa?ref=[latest-release-here]"
  business_unit          = var.business_unit
  application            = var.application
  eks_cluster_name       = var.eks_cluster_name
  namespace              = var.namespace
  service_account_name   = "${var.namespace}-cross-service"
  is_production          = var.is_production
  team_name              = var.team_name
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
  role_policy_arns       = { s3 = aws_iam_policy.s3_migrate_policy.arn }
}

data "aws_iam_policy_document" "s3_migrate_policy" {
  # List & location for source & destination S3 bucket.
  statement {
    actions = [ 
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [ 
      module.s3_bucket.bucket_arn,
      "arn:aws:s3:::[source-bucket-name]"
    ]
  }
  # Permissions on source S3 bucket contents. 
  statement {
    actions = [ 
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging"
    ]
    resources = [ "arn:aws:s3:::[source-bucket-name]/*" ]   # take note of trailing /* here
  }
  # Permissions on destination S3 bucket contents. 
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [ "${module.s3_bucket.bucket_arn}/*" ]
  }
}

resource "aws_iam_policy" "s3_migrate_policy" {
  name   = "s3_migrate_policy"
  policy = data.aws_iam_policy_document.s3_migrate_policy.json

  tags = {
    business-unit          = var.business_unit
    application            = var.application
    is-production          = var.is_production
    environment-name       = var.environment
    owner                  = var.team_name
    infrastructure-support = var.infrastructure_support
  }
}

# store irsa rolearn in k8s secret for retrieving to provide within source bucket policy
resource "kubernetes_secret" "cross_irsa" {
  metadata {
    name      = "cross-irsa-output"
    namespace = var.namespace
  }
  data = {
    role           = module.cross_irsa.role_name
    rolearn        = module.cross_irsa.role_arn
    serviceaccount = module.cross_irsa.service_account.name
  }
}

# set up the service pod
module "cross_service_pod" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-service-pod?ref=[latest-release-here]"
  namespace            = var.namespace
  service_account_name = module.cross_irsa.service_account.name
}
```


#### Source bucket policy

The source bucket must permit your IRSA role to "read" from its bucket explicitly.

First, retrieve the IRSA rolearn using cloud-platform CLI and [jq](https://jqlang.github.io/jq/)

```
cloud-platform decode-secret -s cross-irsa-output | jq -r '.data.rolearn'
```

You should get output similar to below:

```
arn:aws:iam::754256621582:role/cloud-platform-irsa-randomstring1234
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
                "AWS": "arn:aws:iam::754256621582:role/cloud-platform-irsa-randomstring1234"
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

#### Synchronization

Once configured, you can exec into your service pod and execute the following. This will add new, update existing and delete objects (not in source).

```bash
kubectl exec --stdin --tty cloud-platform-7e1f25a0c851c02c-service-pod-abc123 -- /bin/sh

aws s3 sync --delete \
  s3://source_bucket_name \
  s3://destination_bucket_name \
  --source-region source_region \
  --region destination_region
```

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
      serviceAccountName: irsa-service-account-name 
      restartPolicy: Never
      containers:
        - name: tools
          image: ministryofjustice/cloud-platform-tools:2.9.0
          command:
            - /bin/bash
            - -c
            - |
              cd /unpack
              aws s3 cp s3://${S3_BUCKET}/<filename>.bz2 - \
                | bunzip2 \
                | aws s3 cp - s3://${S3_BUCKET}/<filename>
          env:
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

For further guidance on using IRSA, for example accessing AWS buckets in different accounts, see the following links:

[Use IAM Roles for service accounts to access resources in a different AWS account](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/access-cross-aws-resources-irsa-eks.html)

[Accessing AWS APIs and resources from your namespace](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/accessing-aws-apis-and-resources-from-your-namespace.html#accessing-aws-apis-and-resources-from-your-namespace)

[Cloud Platform service pod for AWS CLI access]https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/cloud-platform-service-pod.html)

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
