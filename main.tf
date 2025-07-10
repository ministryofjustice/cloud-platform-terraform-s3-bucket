locals {
  # Generic configuration
  bucket_name   = var.bucket_name == "" ? "cloud-platform-${random_id.id.hex}" : var.bucket_name
  s3_bucket_arn = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"


  # OIDC configuration
  oidc_providers = {
    github = "token.actions.githubusercontent.com"
  }
  enable_github = contains(var.oidc_providers, "github")
  github_repos  = toset(var.github_repositories)
  github_envs   = toset(var.github_environments)
  github_repo_envs = {
    for pair in setproduct(local.github_repos, local.github_envs) :
    "${pair[0]}.${pair[1]}" => {
      repository  = pair[0]
      environment = pair[1]
    }
  }
  github_actions_prefix = upper(var.github_actions_prefix)
  github_variable_names = {
    ROLE_TO_ASSUME = join("_", compact([local.github_actions_prefix, "S3_ROLE_TO_ASSUME"]))
    REGION         = join("_", compact([local.github_actions_prefix, "S3_REGION"]))
    BUCKET_NAME    = join("_", compact([local.github_actions_prefix, "S3_BUCKET_NAME"]))
  }

  # Tags
  default_tags = {
    # Mandatory
    business-unit = var.business_unit
    application   = var.application
    is-production = var.is_production
    owner         = var.team_name
    namespace     = var.namespace # for billing and identification purposes

    # Optional
    environment-name       = var.environment_name
    infrastructure-support = var.infrastructure_support
  }
}

########################
# Generate identifiers #
########################
resource "random_id" "id" {
  byte_length = 16
}

#####################
# Generate policies #
#####################
locals {
  bucket_policy = replace(var.bucket_policy, "$${bucket_arn}", "arn:aws:s3:::${local.bucket_name}")
}

#################
# Create bucket #
#################
# TODO: Split sub-resources into their own resources as part of the terraform-provider-aws
# v4.0.0 release.
resource "aws_s3_bucket" "bucket" {
  bucket        = local.bucket_name
  acl           = var.acl
  force_destroy = "true"
  policy        = local.bucket_policy

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)
      enabled                                = lifecycle_rule.value.enabled
      id                                     = lookup(lifecycle_rule.value, "id", null)
      prefix                                 = lookup(lifecycle_rule.value, "prefix", null)
      tags                                   = lookup(lifecycle_rule.value, "tags", null)

      dynamic "expiration" {
        for_each = lookup(lifecycle_rule.value, "expiration", [])
        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_expiration", [])
        content {
          days = lookup(noncurrent_version_expiration.value, "days", null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_transition", [])
        content {
          days          = lookup(noncurrent_version_transition.value, "days", null)
          storage_class = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", [])
        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }
    }
  }

  dynamic "cors_rule" {
    for_each = var.cors_rule
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = var.versioning
  }

  dynamic "logging" {
    for_each = var.logging_enabled == true ? [1] : []
    content {
      target_bucket = var.log_target_bucket
      target_prefix = var.log_path
    }
  }

  tags = {
    namespace              = var.namespace
    business-unit          = var.business_unit
    application            = var.application
    is-production          = var.is_production
    environment-name       = var.environment_name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure_support
  }
}

##############################
# Create public access block #
##############################
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  count  = var.enable_allow_block_pub_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################
# Create IAM role for access #
##############################
data "aws_iam_policy_document" "irsa" {
  version = "2012-10-17"
  statement {
    sid    = "AllowBucketActionsFor${random_id.id.hex}"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketOwnershipControls",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
    ]
    resources = [local.s3_bucket_arn]
  }

  statement {
    sid    = "AllowObjectActionsFor${random_id.id.hex}"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectVersionTagging",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionAcl",
      "s3:PutObjectVersionTagging",
      "s3:RestoreObject",
    ]
    resources = [
      "${local.s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "irsa" {
  name   = "cloud-platform-s3-${random_id.id.hex}"
  path   = "/cloud-platform/s3/"
  policy = data.aws_iam_policy_document.irsa.json
  tags   = local.default_tags
}


####################
# OIDC integration #
####################
data "aws_region" "current" {}

# GitHub: OIDC provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://${local.oidc_providers.github}"
}

# GitHub: Assume role policy
# See: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#adding-the-identity-provider-to-aws
data "aws_iam_policy_document" "github" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = (length(local.github_repos) == 1) ? "StringLike" : "ForAnyValue:StringLike"
      variable = "${local.oidc_providers.github}:sub"
      values   = formatlist("repo:ministryofjustice/%s:*", local.github_repos)
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_providers.github}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM role and policy attachment for OIDC
resource "aws_iam_role" "github" {
  count = local.enable_github ? 1 : 0

  name               = "cloud-platform-oidc-github-${random_id.id.hex}"
  assume_role_policy = data.aws_iam_policy_document.github.json

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "github" {
  count = local.enable_github ? 1 : 0

  role       = aws_iam_role.github[0].name
  policy_arn = aws_iam_policy.irsa.arn
}

# Actions
resource "github_actions_secret" "github_role_to_assume" {
  for_each = (length(var.github_environments) == 0 && local.enable_github) ? local.github_repos : []

  repository      = each.value
  secret_name     = local.github_variable_names["ROLE_TO_ASSUME"]
  plaintext_value = aws_iam_role.github[0].arn
}

resource "github_actions_variable" "github_region" {
  for_each = (length(var.github_environments) == 0 && local.enable_github) ? local.github_repos : []

  repository    = each.value
  variable_name = local.github_variable_names["REGION"]
  value         = data.aws_region.current.name
}

resource "github_actions_variable" "github_repository" {
  for_each = (length(var.github_environments) == 0 && local.enable_github) ? local.github_repos : []

  repository    = each.value
  variable_name = local.github_variable_names["BUCKET_NAME"]
  value         = aws_s3_bucket.bucket.id
}

# Environments
resource "github_actions_environment_secret" "github_role_to_assume" {
  for_each = local.enable_github ? local.github_repo_envs : {}

  repository      = each.value.repository
  environment     = each.value.environment
  secret_name     = local.github_variable_names["ROLE_TO_ASSUME"]
  plaintext_value = aws_iam_role.github[0].arn
}

resource "github_actions_environment_variable" "github_region" {
  for_each = local.enable_github ? local.github_repo_envs : {}

  repository    = each.value.repository
  environment   = each.value.environment
  variable_name = local.github_variable_names["REGION"]
  value         = data.aws_region.current.name
}

resource "github_actions_environment_variable" "github_repository" {
  for_each = local.enable_github ? local.github_repo_envs : {}

  repository    = each.value.repository
  environment   = each.value.environment
  variable_name = local.github_variable_names["BUCKET_NAME"]
  value         = aws_s3_bucket.bucket.id
}