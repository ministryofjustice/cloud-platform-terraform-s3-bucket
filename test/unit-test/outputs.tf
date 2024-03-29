output "bucket_arn" {
  description = "Arn for s3 bucket created"
  value       = module.s3.bucket_arn
}

output "bucket_name" {
  description = "bucket name"
  value       = module.s3.bucket_name
}
