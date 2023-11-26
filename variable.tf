variable "region" {
  type = string
}
variable "access_key" {
   type = string
}
variable "secret_key" {
   type = string
}
variable "key_name" {
  default = "test"
}

variable "ECR_REPOS" {
  type    = list(string)
  default = ["users"]
}

variable "argocd_namespace" {
  type    = string
  default = "agrocd"
}

variable "enable_vpn" {
  type    = bool
  default = false
}

variable "enable_bastion" {
  type    = bool
  default = false
}

variable "enable_ingress_controller" {
  type    = bool
  default = false
}

variable "enable_agrocd" {
  type    = bool
  default = false
}

variable "enable_ecr" {
  type    = bool
  default = false
}
variable "enabale_prometheus" {
  type    = bool
  default = false
}

variable "enabale_grafana" {
  type    = bool
  default = false
}

variable "create_user" {
  type    = bool
  default = false
}