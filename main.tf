data "aws_caller_identity" "current" {
}


data "aws_region" "current" {
}

resource "random_id" "id" {
  byte_length = 16
}

data "template_file" "bucket_policy" {
  template = var.bucket_policy

  vars = {
    bucket_arn = "arn:aws:s3:::${local.bucket_name}"
  }
}

data "template_file" "user_policy" {
  template = var.user_policy

  vars = {
    bucket_arn = "arn:aws:s3:::${local.bucket_name}"
  }
}

locals {
  bucket_name = var.bucket_name == "" ? "cloud-platform-${random_id.id.hex}" : var.bucket_name
}

resource "aws_s3_bucket" "bucket" {
  bucket        = local.bucket_name
  acl           = var.acl
  force_destroy = "true"
  policy        = data.template_file.bucket_policy.rendered


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
    business-unit          = var.business-unit
    application            = var.application
    is-production          = var.is-production
    environment-name       = var.environment-name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure-support
  }
}

resource "aws_iam_user" "user" {
  name = "s3-bucket-user-${random_id.id.hex}"
  path = "/system/s3-bucket-user/"
}

resource "aws_iam_access_key" "user" {
  user = aws_iam_user.user.name
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.bucket.id}",
    ]
  }

  statement {
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
      "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*",
    ]
  }
}

resource "aws_iam_user_policy" "policy" {
  name   = "s3-bucket-read-write"
  policy = data.template_file.user_policy.rendered == "" ? data.aws_iam_policy_document.policy.json : data.template_file.user_policy.rendered
  user   = aws_iam_user.user.name
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {

  count  = var.enable_allow_block_pub_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

