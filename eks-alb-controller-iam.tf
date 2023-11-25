data "aws_caller_identity" "current" {}

data "http" "alb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json"
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "AWSLBControllerIAMPolicy" {
  name   = "${local.name_prefix}-${local.var.cluster_name}-AWSLBControllerIAMPolicy"
  policy = data.http.alb_controller_policy.body
}

resource "aws_iam_role" "alb_controller" {
  name        = "${local.name_prefix}-${local.var.cluster_name}-aws-load-balancer-controller"
  description = "Permissions required by the Kubernetes AWS ALB Ingress controller to do it's job."

  force_detach_policies = true

  assume_role_policy = <<ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
ROLE
}

resource "aws_iam_role_policy_attachment" "AWSLBControllerIAMPolicy" {
  policy_arn = aws_iam_policy.AWSLBControllerIAMPolicy.arn
  role       = aws_iam_role.alb_controller.name
}