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
variable "allowed_assume_role_arns" {
  default     = []
  description = "Optional list of ARNs of IAM roles this role is allowed to assume."
  type        = list(string)

  validation {
    condition     = alltrue([for arn in var.allowed_assume_role_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", arn))])
    error_message = "All allowed assume role ARNs must be valid IAM role ARNs."
  }
}

variable "managed_policy_arns" {
  default     = {}
  description = "Optional map of managed policy ARNs to attach to the GitHub OIDC role. Keys are names you choose and must be known at plan time; values are the policy ARNs."
  type        = map(string)

  validation {
    condition     = alltrue([for arn in values(var.managed_policy_arns) : can(regex("^arn:aws[a-z-]*:iam::([0-9]{12}|aws):policy/.+$", arn))])
    error_message = "All managed policy ARNs must be valid IAM policy ARNs."
  }

  validation {
    condition     = length(var.managed_policy_arns) <= 10
    error_message = "No more than 10 managed policies may be attached to the GitHub OIDC role."
  }
}

variable "tags" {
  default     = {}
  description = "Additional tags to merge into module tags."
  type        = map(string)
}
