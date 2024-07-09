#################
# Configuration #
#################
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
  type        = any # list(any)
}

variable "cors_rule" {
  description = "cors rule"
  default     = []
  type        = any # list(any)
}

variable "enable_allow_block_pub_access" {
  description = "Enable whether to allow for the bucket to be blocked from public access"
  default     = true
  type        = bool
}

variable "enable_backup" {
  description = "Enable to use AWS Backup to backup the bucket"
  default     = false
  type        = bool
}

variable "backup_schedule" {
  description = "Cron for setting the backup schedule"
  default     = "cron(0 5 ? * * *)"
  type        = string
}

variable "backup_retention_days" {
  description = "The number of days a backup is kept for"
  default     = 35
  type        = number
}

variable "backup_restore" {
  description = "Enable so restore from backup is able to be performed (enables ACLs)"
  default     = false
  type        = bool
}

########
# Tags #
########
variable "business_unit" {
  description = "Area of the MOJ responsible for the service"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "is_production" {
  description = "Whether this is used for production or not"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "namespace" {
  description = "Namespace name"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "infrastructure_support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  type        = string
}
