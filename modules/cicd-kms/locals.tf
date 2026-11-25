locals {
  # Aws
  current_account_id = data.aws_caller_identity.current.account_id
  current_partition  = data.aws_partition.current.partition
  # Tags
  common_tags = merge(
    {
      "terraform:module:repository" = "https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/cicd-kms"
      "terraform:module"            = "terraform-aws-flagscript-cicd//modules/cicd-kms"
    },
    var.tags
  )
}
