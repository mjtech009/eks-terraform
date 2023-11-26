locals {
  var = yamldecode(file("env.eks.yaml"))
}

locals {
  name_prefix = "${local.var.project}-${local.var.environment}"
}