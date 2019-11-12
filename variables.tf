variable "team_name" {}

variable "application" {}

variable "environment-name" {}

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

variable "lifecycle_rule" {
  description = "lifecycle"
  default     = []
}

variable "cors_rule" {
  description = "cors rule"
  default = []
}
