locals {
  var = yamldecode(file("env.${terraform.workspace}.yaml"))
}

locals {
  name_prefix = "${local.var.project}-${local.var.environment}"
}