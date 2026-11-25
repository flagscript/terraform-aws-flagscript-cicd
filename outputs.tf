# S3
output "terraform_state_bucket_arn" {
  description = "Regional map of ARN for the S3 bucket."
  value       = { for region in local.deployment_regions : region => aws_s3_bucket.terraform_state_bucket[region].arn }
}

output "terraform_state_bucket_name" {
  description = "Regional map of name for the S3 bucket."
  value       = { for region in local.deployment_regions : region => aws_s3_bucket.terraform_state_bucket[region].bucket }
}

# Iam
output "terraform_state_bucket_access_policy_arn" {
  description = "The ARN of the policy that allows access to the terraform state bucket."
  value       = aws_iam_policy.terraform_state_bucket_access_policy.arn
}
