module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${local.name_prefix}-${local.var.cluster_name}"
  cluster_version = local.var.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = aws_vpc.vpc.id
  subnet_ids               = flatten([aws_subnet.private_subnet.*.id])
  control_plane_subnet_ids = flatten([aws_subnet.public_subnet[*].id, aws_subnet.private_subnet[*].id])

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t3.medium"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }
  eks_managed_node_groups = {
    green = {
      min_size     = 6
      max_size     = 6
      desired_size = 6

      instance_types = local.var.cluster_instance_types
      capacity_type  = "ON_DEMAND"
    }
  }


  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "${data.aws_iam_role.terraform_role.arn}"
      username = "admin1"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "${data.aws_iam_role.github_role.arn}"
      username = "admin2"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "${aws_iam_role.eks_ec2_role.arn}"
      username = "admin3"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Environment = local.var.environment
    Project     = local.var.project
  }
}


resource "aws_iam_role" "eks_ec2_role" {
  name = "${local.name_prefix}-EKS-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eks_full_access_policy" {
  name        = "${local.name_prefix}-EKS-bastion-policy"
  description = "IAM policy granting full access to EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "eks:*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_eks_full_access_policy" {
  policy_arn = aws_iam_policy.eks_full_access_policy.arn
  role       = aws_iam_role.eks_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "attach_ssm_access_policy" {
  policy_arn = data.aws_iam_policy.ssm.arn
  role       = aws_iam_role.eks_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "attach_IAM_access_policy" {
  policy_arn = data.aws_iam_policy.IAM.arn
  role       = aws_iam_role.eks_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "attach_cf_access_policy" {
  policy_arn = data.aws_iam_policy.cf.arn
  role       = aws_iam_role.eks_ec2_role.name
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}


data "aws_iam_policy" "IAM" {
  arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

data "aws_iam_policy" "cf" {
  arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}
data "aws_iam_role" "terraform_role" {
  name = "TERRAFORM_CLOUD_ROLE"
}

data "aws_iam_role" "github_role" {
  name = "GitHub_Action_Role"
}