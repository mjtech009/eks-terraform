provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = local.var.environment
      Project     = local.var.project
    }
  }
}


data "aws_eks_cluster_auth" "eks_cluster" {
  name = module.eks.cluster_name
}

# provider "kubernetes" {  
#   host                   = aws_eks_cluster.eks_cluster.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks_cluster.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.eks_cluster.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks_cluster.token
#   }
# }

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks_cluster.token
  }
}
