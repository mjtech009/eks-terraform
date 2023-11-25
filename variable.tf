variable "region" {
  type = string
}

variable "key_name" {
  default = "test"
}

variable "ECR_REPOS" {
  type    = list(string)
  default = ["users"]

}

variable "FRONTEND_CODE_COMMIT_REPOS" {
  type    = list(string)
  default = ["frontend"]
}

variable "BACKEND_CODE_COMMIT_REPOS" {
  type    = set(string)
  default = ["frontend"]
}

variable "restriction_type" {
  default = "none"
}

variable "blacklist_countries" {
  default = []
}

variable "TFC_AWS_RUN_ROLE_ARN" {
  type = string
}

variable "TFC_AWS_PROVIDER_AUTH" {
  type = string
}

variable "enable_user_pool" {
  type    = bool
  default = true
}

variable "sso_enabled_envs" {
  type    = list(string)
  default = ["dev", "uat"]
}