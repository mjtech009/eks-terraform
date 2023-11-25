resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    templatefile("${path.module}/values/alb-controller/alb-controller.yaml", {
      cluster_name    = "${local.name_prefix}-${local.var.cluster_name}"
      service_account = kubernetes_service_account.alb_controller.metadata[0].name
    })
  ]
}

# Create K8s service account and associate the IAM role we created in alb-controller-iam.tf
resource "kubernetes_service_account" "alb_controller" {
  automount_service_account_token = true
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

resource "kubernetes_cluster_role" "alb_controller" {
  metadata {
    name = "aws-load-balancer-controller"
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints", "namespaces", "nodes", "pods", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  # add services/status rule 

  rule {
    api_groups = ["", "extensions", "elbv2.k8s.aws", "networking.k8s.io"]
    resources  = ["pods/status", "services", "ingresses/status", "targetgroupbindings/status", "services/status"]
    verbs      = ["patch", "update"]
  }

  rule {
    api_groups = ["", "extensions", "networking.k8s.io"]
    resources  = ["services", "ingresses", "configmaps", "ingressclasses"]
    verbs      = ["create", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = ["elbv2.k8s.aws"]
    resources  = ["targetgroupbindings", "ingressclassparams"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }
}

# Create a Cluster Role and Cluster Role Binding that grant requisite permissions to the Service Account
# created above
resource "kubernetes_cluster_role_binding" "alb_controller" {
  metadata {
    name = "aws-load-balancer-controller"
    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
      # "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.alb_controller.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.alb_controller.metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [kubernetes_cluster_role.alb_controller]
}

# Create a Role and Role Binding that grant requisite permissions to the Service Account

resource "kubernetes_role_v1" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller-leader-election-role"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }


  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = [""]
    verbs          = ["create"]
  }
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["aws-load-balancer-controller-leader"]
    verbs          = ["get", "update", "patch"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create"]
  }
  rule {
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    resource_names = ["aws-load-balancer-controller-leader"]
    verbs          = ["get", "update", "patch"]
  }
}


resource "kubernetes_role_binding_v1" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller-leader-election-rolebinding"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.alb_controller.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.alb_controller.metadata[0].name
    namespace = "kube-system"
  }
}