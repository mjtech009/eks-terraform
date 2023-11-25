# EKS Node Group Outputs - Private

# output "node_group_private_id" {
#   description = "Node Group 1 ID"
#   value       = aws_eks_node_group.eks_ng_private.id
# }

# output "node_group_private_arn" {
#   description = "Private Node Group ARN"
#   value       = aws_eks_node_group.eks_ng_private.arn
# }

# output "node_group_private_status" {
#   description = "Private Node Group status"
#   value       = aws_eks_node_group.eks_ng_private.status
# }

# output "node_group_private_version" {
#   description = "Private Node Group Kubernetes Version"
#   value       = aws_eks_node_group.eks_ng_private.version
# }

# output "command_for_add_context" {
#   value = "aws eks update-kubeconfig --region ${local.var.region} --name ${aws_eks_cluster.eks_cluster.name}"
# }

# Output of Mongodb

output "mongodb_username" {
  value = "mongo_admin"

}

output "mongodb_Password" {
  value = random_string.db_password.result

}

output "mongodb_endpoint" {
  value = aws_instance.mongodb.private_ip
}