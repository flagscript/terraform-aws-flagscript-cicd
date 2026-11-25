locals {
  # AWS
  current_account_id = data.aws_caller_identity.current.account_id
  deployment_regions = compact([var.primary_region, var.secondary_region])
  # Resource
  enable_replication        = var.secondary_region != null
  state_bucket_prefix_title = replace(title(var.state_bucket_prefix), "-", "")
  # Tagging
  common_tags = merge(
    {
      "terraform:module:repository" = "https://github.com/flagscript/terraform-aws-flagscript-cicd"
      "terraform:module"            = "flagscript-cicd"
    },
    var.tags
  )
}
