# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
variable "github_repository_paths" {
  description = "The GitHub repository paths that are allowed to assume this role. For example, 'repo:owner/repo:ref:refs/heads/main'."
  type        = list(string)
}

variable "role_prefix" {
  description = "The prefix for the role name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z]+$", var.role_prefix))
    error_message = "Variable role_prefix may only contain letters."
  }
}

# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
variable "managed_policy_arns_to_attach" {
  default     = []
  description = "Optional list of managed policy ARNs to attach to the GitHub OIDC role."
  type        = list(string)

  validation {
    condition     = length(var.managed_policy_arns_to_attach) <= 10
    error_message = "No more than 10 managed policy ARNs may be attached to the GitHub OIDC role."
  }

}
variable "tags" {
  default     = {}
  description = "Additional tags to merge into module tags."
  type        = map(string)
}
