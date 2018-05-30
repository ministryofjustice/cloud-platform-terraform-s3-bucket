data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.team_name}-${var.bucket_name}"
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
  name = "${aws_s3_bucket.bucket.bucket}-s3-account"
  path = "/teams/${var.team_name}/"
}

resource "aws_iam_access_key" "s3-account-access-keys" {
  user = "${aws_iam_user.s3-account.name}"
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetObject",
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${var.team_name}-s3-policy"
  path        = "/teams/${var.team_name}/"
  policy      = "${data.aws_iam_policy_document.policy.json}"
  description = "S3 policy for team ${var.team_name}"
}

resource "aws_iam_policy_attachment" "attach-policy" {
  name       = "attached-policy"
  users      = ["${aws_iam_user.s3-account.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}
