variable "team_name" {}

variable "bucket_identifier" {
  description = "This is the bucket identifier, the bucket name will be this prefixed with your team name"
}

variable "acl" {
  description = "acl manages access to your bucket"
  default     = "private"
}

variable "versioning" {
  description = "version objects stored within your bucket. "
  default     = false
}

variable "business-unit" {}

variable "application" {}

variable "is-production" {
  default = false
}

variable "environment-name" {}

variable "infrastructure-support" {}
