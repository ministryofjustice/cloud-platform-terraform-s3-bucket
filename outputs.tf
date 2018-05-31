output "policy_arn" {
  description = "ARN for the new policy"
  value       = "${aws_iam_policy.policy.arn}"
}

output "iam_user_name" {
  description = "user name for s3 service account"
  value       = "${aws_iam_user.s3-account.name}"
}

output "access_key_id" {
  description = "Access key id for s3 account"
  value       = "${aws_iam_access_key.s3-account-access-key.id}"
}

output "secret_access_key" {
  description = "Secret key for s3 account"
  value       = "${aws_iam_access_key.s3-account-access-key.secret}"
}

output "bucket_arn" {
  description = "Arn for s3 bucket created"
  value       = "${aws_s3_bucket.s3bucket.arn}"
}

output "bucket_name" {
  description = "bucket name"
  value       = "${aws_s3_bucket.s3bucket.bucket}"
}

output "user_arn" {
  description = "Arn for iam user"
  value       = "${aws_iam_user.s3-account.arn}"
}
