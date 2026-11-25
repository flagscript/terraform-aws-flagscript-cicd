output "terraform_state_bucket_name" {
  description = "Regional map of Terraform state bucket names."
  value       = module.cicd.terraform_state_bucket_name
}

output "terraform_state_bucket_access_policy_arn" {
  description = "ARN of the policy that grants access to the Terraform state bucket(s)."
  value       = module.cicd.terraform_state_bucket_access_policy_arn
}
