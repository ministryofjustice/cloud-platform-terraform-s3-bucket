data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_id" "id" {
  byte_length = 16
}

data "template_file" "bucket_policy" {
  template = "${var.bucket_policy}"

  vars {
    bucket_arn = "arn:aws:s3:::cloud-platform-${random_id.id.hex}"
  }
}

data "template_file" "user_policy" {
  template = "${var.user_policy}"

  vars {
    bucket_arn = "arn:aws:s3:::cloud-platform-${random_id.id.hex}"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "cloud-platform-${random_id.id.hex}"
  acl           = "${var.acl}"
  force_destroy = "true"
  policy        = "${data.template_file.bucket_policy.rendered}"

  lifecycle_rule = "${var.lifecycle_rule}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = "${var.versioning}"
  }

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}

resource "aws_iam_user" "user" {
  name = "s3-bucket-user-${random_id.id.hex}"
  path = "/system/s3-bucket-user/${var.team_name}/"
}

resource "aws_iam_access_key" "user" {
  user = "${aws_iam_user.user.name}"
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
  policy = "${data.template_file.user_policy.rendered == "" ? data.aws_iam_policy_document.policy.json : data.template_file.user_policy.rendered}"
  user   = "${aws_iam_user.user.name}"
}
