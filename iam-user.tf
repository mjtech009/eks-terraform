# Create IAM User
resource "aws_iam_user" "user" {
  count = var.create_user ? 1 : 0
  name  = "eks-admin-user"
}

# Create Access Key for the IAM User
resource "aws_iam_access_key" "user_access_key" {
  count = var.create_user ? 1 : 0
  user  = aws_iam_user.user.name
}

resource "aws_ssm_parameter" "access_key" {
  count = var.create_user ? 1 : 0
  name  = "/iam/eks-admin-user/access-key/"
  type  = "SecureString"
  value = aws_iam_access_key.user_access_key.id
}

resource "aws_ssm_parameter" "secret_key" {
  count = var.create_user ? 1 : 0
  name  = "/iam/eks-admin-user/secret-key/"
  type  = "SecureString"
  value = aws_iam_access_key.user_access_key.secret
}

# Create Login Profile for the IAM User
resource "aws_iam_user_login_profile" "user_login_profile" {
  count                   = var.create_user ? 1 : 0
  user                    = aws_iam_user.user.name
  password_reset_required = true
}


# Attach IAM Policies for EKS, ECR, CloudWatch, and ALB to the IAM User
resource "aws_iam_user_policy_attachment" "user_policy_eks" {
  count      = var.create_user ? 1 : 0
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_user_policy_attachment" "user_policy_ecr" {
  count      = var.create_user ? 1 : 0
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_user_policy_attachment" "user_policy_cloudwatch" {
  count      = var.create_user ? 1 : 0
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_user_policy_attachment" "user_policy_alb" {
  count      = var.create_user ? 1 : 0
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
