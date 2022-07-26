variable "team_name" {
  description = "Your team name"
  type        = string
}

variable "application" {
  description = "Your application name"
  type        = string
}

variable "environment-name" {
  description = "Your environment name"
  type        = string
}

variable "namespace" {
  description = "Your namespace"
  type        = string
}

variable "business-unit" {
  description = "Area of the MOJ responsible for the service"
  default     = "mojdigital"
  type        = string
}

variable "is-production" {
  default     = "false"
  description = "Whether this S3 bucket is for production or not"
  type        = string
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  type        = string
}

variable "acl" {
  description = "The bucket ACL to set"
  default     = "private"
  type        = string
}

variable "bucket_policy" {
  description = "The S3 bucket policy to set. If empty, no policy will be set"
  default     = ""
  type        = string
}

variable "user_policy" {
  description = "The IAM policy to assign to the generated user. If empty, the default policy is used"
  default     = ""
  type        = string
}

variable "versioning" {
  description = "Enable object versioning for the bucket"
  default     = false
  type        = bool
}

variable "log_target_bucket" {
  description = "Set the target bucket for logs"
  default     = ""
  type        = string
}

variable "logging_enabled" {
  description = "Set the logging for bucket"
  default     = false
  type        = bool
}

variable "bucket_name" {
  description = "Set the name of the S3 bucket. If left blank, a name will be automatically generated (recommended)"
  default     = ""
  type        = string
}

variable "log_path" {
  description = "Set the path of the logs"
  default     = ""
  type        = string
}

variable "lifecycle_rule" {
  description = "lifecycle"
  default     = []
  type        = list(any)
}

variable "cors_rule" {
  description = "cors rule"
  default     = []
  type        = list(any)
}

variable "enable_allow_block_pub_access" {
  description = "Enable whether to allow for the bucket to be blocked from public access"
  default     = true
  type        = bool
}
