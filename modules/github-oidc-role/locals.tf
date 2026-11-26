locals {
  # Resources
  create_assume_role_policy = length(var.allowed_assume_role_arns) > 0
  # Tags
  common_tags = merge(
    {
      "terraform:module:repository" = "https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/github-oidc-role"
      "terraform:module"            = "terraform-aws-flagscript-cicd//modules/github-oidc-role"
    },
    var.tags
  )
}
