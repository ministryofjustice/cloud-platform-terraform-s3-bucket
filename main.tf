data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "s3bucket" {
  bucket        = "${var.team_name}-${var.bucket_identifier}"
  acl           = "${var.acl}"
  force_destroy = "true"
  region        = "${data.aws_region.current.name}"

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
}

resource "aws_iam_user" "s3-account" {
  name = "${aws_s3_bucket.s3bucket.bucket}-s3-system-account"
  path = "/teams/${var.team_name}/"
}

resource "aws_iam_access_key" "s3-account-access-key" {
  user = "${aws_iam_user.s3-account.name}"
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "s3:GetBucketTagging",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:ListBucketVersions",
      "s3:GetBucketLogging",
      "s3:RestoreObject",
      "s3:ReplicateObject",
      "s3:GetObjectVersionTorrent",
      "s3:GetObjectAcl",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload",
      "s3:GetBucketRequestPayment",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:GetIpConfiguration",
      "s3:DeleteObjectTagging",
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketWebsite",
      "s3:PutObjectVersionTagging",
      "s3:DeleteObjectVersionTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketNotification",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectTorrent",
      "s3:GetBucketCORS",
      "s3:GetObjectVersionForReplication",
      "s3:GetBucketLocation",
      "s3:ReplicateDelete",
      "s3:GetObjectVersion",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.s3bucket.bucket}/*",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${aws_s3_bucket.s3bucket.bucket}-s3-policy"
  path        = "/teams/${var.team_name}/"
  policy      = "${data.aws_iam_policy_document.policy.json}"
  description = "Policy for S3 bucket ${aws_s3_bucket.s3bucket.bucket}"
}

resource "aws_iam_policy_attachment" "attach-policy" {
  name       = "attached-policy"
  users      = ["${aws_iam_user.s3-account.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}
