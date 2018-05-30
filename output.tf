output "policy_arn" {
  description = "ARN for the new policy"
  value       = "${aws_iam_policy.policy.arn}"
}

output "iam_am_user" {
  description = "user name for s3 service account"
  value       = "${aws_iam_user.s3-account.name}"
}

output "access_key_id" {
  description = "Access keys id"
  value       = "${aws_iam_access_key.s3-account-access-keys.id}"
}

output "secret_access_key" {
  description = "Secret key for s3 account"
  value       = "${aws_iam_access_key.s3-account-access-keys.secret}"
}

output "bucket_arn" {
  description = "Arn for s3 bucket created"
  value       = "${aws_s3_bucket.bucket.arn}"
}

output "bucket_name" {
  description = "bucket name"
  value       = "${aws_s3_bucket.bucket.bucket}"
}

output "user_arn" {
  description = "Arn for iam user"
  value       = "${aws_iam_user.s3-account.arn}"
}
