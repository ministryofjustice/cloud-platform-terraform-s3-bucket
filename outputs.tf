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
  value       = "${aws_s3_bucket.bucket.bucket}"
}
