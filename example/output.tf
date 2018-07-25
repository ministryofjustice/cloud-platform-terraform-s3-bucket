output "iam_user_name" {
  description = "User name for s3 service account"
  value       = "${module.example_team_s3.iam_user_name}"
}

output "access_key_id" {
  description = "Access key id for s3 account"
  value       = "${module.example_team_s3.access_key_id}"
}

output "secret_access_key" {
  description = "Secret key for s3 account"
  value       = "${module.example_team_s3.secret_access_key}"
}

output "bucket_arn" {
  description = "Arn for s3 bucket created"
  value       = "${module.example_team_s3.bucket_arn}"
}

output "bucket_name" {
  description = "bucket name"
  value       = "${module.example_team_s3.bucket_name}"
}

output "user_arn" {
  description = "ARN for iam user"
  value       = "${module.example_team_s3.user_arn}"
}
