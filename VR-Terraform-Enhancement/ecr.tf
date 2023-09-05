resource "aws_ecr_repository" "self-cast" {
  count = length(local.workspace.ecr.repo_names)
  name                 = "${local.workspace.project_name}-${local.workspace.environment_name}-${local.workspace.ecr.repo_names[count.index]}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  tags = {
    "Project"     = local.workspace.project_name
    "ManagedBy"   = "Terraform"
    "Environment" = local.workspace.environment_name
  }
}

resource "aws_ecr_lifecycle_policy" "auto-remove" {
  count = length(local.workspace.ecr.repo_names)
  repository = aws_ecr_repository.self-cast[count.index].id
  policy     = file("${path.module}/ecr_lifecycle_policy.json")
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  count = length(local.workspace.ecr.repo_names)
  repository = aws_ecr_repository.self-cast[count.index].id
  policy     = file("${path.module}/ecr_policy.json")
}