resource "kubernetes_manifest" "ingress" {
  for_each = { for env in local.var.envs : "api.${env.domain}" => env }
  manifest = yamldecode(templatefile("values/${each.value.name}-backend-api-ingress.yaml", { name = "${each.value.name}-${each.value.type}", alb_group_name = "${local.name_prefix}-alb", certificate_arn = aws_acm_certificate.acm[each.value.domain].arn, domain = each.value.domain }))
}