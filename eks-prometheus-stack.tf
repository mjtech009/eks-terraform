locals {
  prometheus_namespace = "prometheus"
  prometheus_enabled   = local.var.prometheus_enabled == true ? 1 : 0
}

resource "kubernetes_namespace" "prometheus" {
  count = local.prometheus_enabled
  metadata {
    annotations = {
      name = local.prometheus_namespace
    }

    name = local.prometheus_namespace
  }
}

resource "random_id" "grafana_password" {
  count       = local.prometheus_enabled
  byte_length = 8
}

resource "aws_ssm_parameter" "grafana_password" {
  count = local.prometheus_enabled
  name  = "/${local.var.environment}/grafana/password"
  type  = "SecureString"
  value = random_id.grafana_password.0.hex
}

data "aws_route53_zone" "current" {
  count = local.prometheus_enabled
  name  = local.var.prometheus_domain
}

module "acm_grafana" {
  count                = local.prometheus_enabled
  source               = "terraform-aws-modules/acm/aws"
  domain_name          = "grafana.${local.var.prometheus_domain}"
  zone_id              = data.aws_route53_zone.current.0.id
  create_certificate   = true
  validate_certificate = true
  wait_for_validation  = true
}

resource "helm_release" "prometheus_stack" {
  count      = local.prometheus_enabled
  name       = "kube-prometheus-stack"
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = kubernetes_namespace.prometheus.0.metadata.0.name

  values = [
    templatefile("${path.module}/values/prometheus-stack/prometheus-stack.yaml", {
      group_name              = "${local.name_prefix}-alb"
      domain                  = local.var.prometheus_domain
      grafana_admin_password  = random_id.grafana_password.0.hex
      grafana_certificate_arn = module.acm_grafana.0.acm_certificate_arn
    })
  ]
}
