variable "team_name" {
}

variable "application" {
}

variable "environment-name" {
}

variable "namespace" {
}

variable "business-unit" {
  description = "Area of the MOJ responsible for the service"
  default     = "mojdigital"
}

variable "is-production" {
  default = "false"
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
}

variable "acl" {
  description = "The bucket ACL to set"
  default     = "private"
}

variable "bucket_policy" {
  description = "The S3 bucket policy to set. If empty, no policy will be set"
  default     = ""
}

variable "user_policy" {
  description = "The IAM policy to assign to the generated user. If empty, the default policy is used"
  default     = ""
}

variable "versioning" {
  description = "Enable object versioning for the bucket"
  default     = false
}

variable "log_target_bucket" {
  description = "Set the target bucket for logs"
  default     = ""
}

variable "logging_enabled" {
  description = "Set the logging for bucket"
  default     = false
}

variable "bucket_name"{
  description = "Set the name of the S3 bucket. If left blank, a name will be automatically generated (recommended)"
  default = ""
}

variable "log_path" {
  description = "Set the path of the logs"
  default     = ""
}


variable "lifecycle_rule" {
  description = "lifecycle"
  default     = []
}

variable "cors_rule" {
  description = "cors rule"
  default     = []
}


variable "enable_allow_block_pub_access" {
  description = "Enable whether to allow for the bucket to be blocked from public access"
  default     = true
  type        = bool
}
