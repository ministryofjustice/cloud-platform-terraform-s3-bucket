output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_domain_name" {
  description = "Regional bucket domain name"
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "irsa_policy_arn" {
  description = "IAM policy ARN for access to the S3 bucket"
  value       = aws_iam_policy.irsa.arn
}
