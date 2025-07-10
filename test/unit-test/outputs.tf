output "bucket_arn" {
  description = "Arn for s3 bucket created"
  value       = module.s3.bucket_arn
}

output "bucket_name" {
  description = "bucket name"
  value       = module.s3.bucket_name
}

output "oidc_role_arn" {
  description = "oidc role arn"
  value       = module.s3_with_oidc.github_oidc_role_arn
}

output "oidc_role_arn_empty" {
  description = "oidc role arn"
  value       = module.s3.github_oidc_role_arn
}
