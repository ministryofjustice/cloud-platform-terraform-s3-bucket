output "access_key_id" {
  description = "Access key id for s3 account"
  value       = aws_iam_access_key.user.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret key for s3 account"
  value       = aws_iam_access_key.user.secret
  sensitive   = true
}

output "bucket_arn" {
  description = "Arn for s3 bucket created"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_name" {
  description = "bucket name"
  value       = aws_s3_bucket.bucket.id
}

output "irsa_policy_arn" {
  value = aws_iam_policy.irsa.arn
}
