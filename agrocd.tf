#https://artifacthub.io/packages/helm/argo/argo-cd

module "iam_assumable_role_oidc" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.2.0"

  create_role                   = true
  role_name                     = "k8s-argocd-admin"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.argocd_namespace}:argocd-server", "system:serviceaccount:${var.argocd_namespace}:argocd-application-controller"]
}

resource "kubernetes_namespace" "namespace_argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd"
  version    = "5.51.4"
  namespace  = var.argocd_namespace
  #values     = [file("${path.module}/values.yaml")]

  ## Server params
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set { # Manage Argo CD configmap (Declarative Setup)
    name  = "server.configEnabled"
    value = "true"
  }

  set { # Argo CD server name
    name  = "server.name"
    value = "argocd-server"
  }

  set { # Annotations applied to created service account
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_oidc.iam_role_arn
  }

  set { # Define the application controller --app-resync - refresh interval for apps, default is 180 seconds
    name  = "controller.args.appResyncPeriod"
    value = "30"
  }

  set { # Define the application controller --repo-server-timeout-seconds - repo refresh timeout, default is 60 seconds
    name  = "controller.args.repoServerTimeoutSeconds"
    value = "15"
  }

  depends_on = [
    kubernetes_namespace.namespace_argocd,
    module.iam_assumable_role_oidc
  ]

}