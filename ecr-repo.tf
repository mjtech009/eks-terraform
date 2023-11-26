resource "aws_ecr_repository" "ecr" {
  count                = var.enable_ecr ? length(var.ECR_REPOS) : 0
  name                 = "${local.name_prefix}-${var.ECR_REPOS[count.index]}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}






