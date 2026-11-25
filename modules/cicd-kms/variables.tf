# REQUIRED PARAMETERS
variable "key_name" {
  description = "The name of the KMS key."
  type        = string

  validation {
    condition     = can(regex("^[a-z-]+$", var.key_name))
    error_message = "Variable key_name may only contain lowercase letters and hyphens."
  }
}

variable "primary_region" {
  description = "Region of the primary key."
  type        = string
}

# These parameters must be supplied when consuming this module.

# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
variable "deletion_window_in_days" {
  default     = 30
  description = "The waiting period, specified in number of days. "
  type        = number

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Variable deletion_window_in_days must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  default     = false
  description = "Specifies whether key rotation is enabled."
  type        = bool
}

variable "enable_key" {
  default     = true
  description = "Specifies whether the cicd key is enabled."
  type        = bool
}

variable "replica_regions" {
  default     = []
  description = "List of regions to create replica keys in."
  type        = list(string)

  validation {
    condition     = length(var.replica_regions) == length(distinct(var.replica_regions))
    error_message = "Variable replica_regions must not contain duplicate regions."
  }

  validation {
    condition     = !contains(var.replica_regions, var.primary_region)
    error_message = "Variable replica_regions must not contain the primary region."
  }
}

variable "tags" {
  default     = {}
  description = "Additional tags to merge into module tags."
  type        = map(string)
}
