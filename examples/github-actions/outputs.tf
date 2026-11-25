output "terraform_state_bucket_name" {
  description = "Regional map of Terraform state bucket names."
  value       = module.cicd.terraform_state_bucket_name
}

output "github_oidc_role_arn" {
  description = "ARN of the role for GitHub Actions to assume."
  value       = module.github_role.github_oidc_role_arn
}
