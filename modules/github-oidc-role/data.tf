data "aws_iam_openid_connect_provider" "github_oidc_provider" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy" "permissions_boundary_policy" {
  count = local.use_permissions_boundary ? 1 : 0
  name  = var.permissions_boundary_policy_name
}
