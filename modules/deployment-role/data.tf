# Aws
data "aws_organizations_organization" "organization" {}

# Iam
data "aws_iam_policy" "permissions_boundary_policy" {
  count = local.use_permissions_boundary ? 1 : 0
  name  = var.permissions_boundary_policy_name
}
