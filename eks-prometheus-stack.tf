locals {
  prometheus_namespace = "prometheus"
}

resource "kubernetes_namespace" "prometheus" {
  count = var.enabale_prometheus ? 1 :0 
  metadata {
    annotations = {
      name = local.prometheus_namespace
    }

    name = local.prometheus_namespace
  }
}

resource "random_id" "grafana_password" {
  count       = var.enabale_prometheus ? 1 :0 
  byte_length = 8
}

resource "aws_ssm_parameter" "grafana_password" {
  count = var.enabale_prometheus ? 1 :0 
  name  = "/${local.var.environment}/grafana/password"
  type  = "SecureString"
  value = random_id.grafana_password.0.hex
}

data "aws_route53_zone" "current" {
  count = var.enabale_prometheus ? 1 :0 
  name  = local.var.prometheus_domain
}

module "acm_grafana" {
  count                = var.enabale_prometheus ? 1 :0 
  source               = "terraform-aws-modules/acm/aws"
  domain_name          = "grafana.${local.var.prometheus_domain}"
  zone_id              = data.aws_route53_zone.current.0.id
  create_certificate   = true
  validate_certificate = true
  wait_for_validation  = true
}

resource "helm_release" "prometheus_stack" {
  count      = var.enabale_prometheus ? 1 :0 
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
