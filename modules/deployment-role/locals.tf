locals {
  # Aws
  organization_id = data.aws_organizations_organization.organization.id
  # Resources
  use_permissions_boundary = var.permissions_boundary_policy_name != null
  # Tags
  common_tags = merge(
    {
      "terraform:module:repository" = "https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/deployment-role"
      "terraform:module"            = "terraform-aws-flagscript-cicd//modules/deployment-role"
    },
    var.tags
  )
}
