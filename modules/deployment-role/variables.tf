# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
variable "role_prefix" {
  description = "The prefix for the role name. Will be appended with 'DeploymentRole' to form the full role name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z]+$", var.role_prefix))
    error_message = "Variable role_prefix may only contain letters."
  }
}

variable "trusted_assume_role_arns" {
  description = "The ARNs of the trusted IAM roles that are allowed to assume this role."
  type        = list(string)

  validation {
    condition     = length(var.trusted_assume_role_arns) > 0
    error_message = "At least one trusted assume role ARN must be specified."
  }

  validation {
    condition     = alltrue([for arn in var.trusted_assume_role_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", arn))])
    error_message = "All trusted assume role ARNs must be valid IAM role ARNs."
  }
}

# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
variable "inline_policy_json_document" {
  default     = null
  description = "Optional JSON document containing the inline policy to attach to the deployment role."
  type        = string
}

variable "managed_policy_arns" {
  default     = {}
  description = "Optional map of managed policy ARNs to attach to the deployment role. Keys are names you choose and must be known at plan time; values are the policy ARNs."
  type        = map(string)

  validation {
    condition     = alltrue([for arn in values(var.managed_policy_arns) : can(regex("^arn:aws[a-z-]*:iam::([0-9]{12}|aws):policy/.+$", arn))])
    error_message = "All managed policy ARNs must be valid IAM policy ARNs."
  }

  validation {
    condition     = length(var.managed_policy_arns) <= 10
    error_message = "No more than 10 managed policies may be attached to the deployment role."
  }
}

variable "permissions_boundary_policy_name" {
  default     = null
  description = "Optional name of the permissions boundary policy to attach to the deployment role."
  type        = string
}

variable "tags" {
  default     = {}
  description = "Additional tags to merge into module tags."
  type        = map(string)
}
