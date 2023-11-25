resource "kubernetes_namespace" "namespace" {
  for_each = { for env in local.var.envs : "${env.name}-${env.type}" => env }
  metadata {
    name = "${each.value.name}-${each.value.type}"
  }
}