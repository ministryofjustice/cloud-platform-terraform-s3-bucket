output "access_key_id" {
  description = "Access key id for s3 account"
  value       = aws_iam_access_key.user_2023.id
}

output "secret_access_key" {
  description = "Secret key for s3 account"
  value       = aws_iam_access_key.user_2023.secret
}

output "bucket_arn" {
  description = "Arn for s3 bucket created"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_name" {
  description = "bucket name"
  value       = aws_s3_bucket.bucket.id
}

