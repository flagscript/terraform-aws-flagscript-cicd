# Iam
output "deployment_role_arn" {
  description = "The ARN of the deployment role."
  value       = aws_iam_role.deployment_role.arn
}

output "deployment_role_name" {
  description = "The name of the deployment role."
  value       = aws_iam_role.deployment_role.name
}
