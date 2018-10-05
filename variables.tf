variable "team_name" {}

variable "application" {}

variable "environment-name" {}

variable "business-unit" {
  description = " Area of the MOJ responsible for the service"
  default     = "mojdigital"
}

variable "is-production" {
  default = "false"
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
}

variable "acl" {
  description = "acl manages access to your bucket"
  default     = "private"
}

variable "versioning" {
  description = "version objects stored within your bucket. "
  default     = false
}
