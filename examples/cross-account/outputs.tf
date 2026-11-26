output "terraform_state_bucket_name" {
  description = "Regional map of Terraform state bucket names in the CI/CD account."
  value       = module.cicd.terraform_state_bucket_name
}

output "github_oidc_role_arn" {
  description = "ARN of the role for GitHub Actions to assume in the CI/CD account."
  value       = module.github_role.github_oidc_role_arn
}

output "deployment_role_arn" {
  description = "ARN of the deployment role in the workload account."
  value       = module.deployment_role.deployment_role_arn
}
