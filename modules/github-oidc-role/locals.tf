locals {
  # Resources
  create_assume_role_policy = length(var.allowed_assume_role_arns) > 0
  use_permissions_boundary  = var.permissions_boundary_policy_name != null
  # Tags
  common_tags = merge(
    {
      "terraform:module:repository" = "https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/github-oidc-role"
      "terraform:module"            = "terraform-aws-flagscript-cicd//modules/github-oidc-role"
    },
    var.tags
  )
}
