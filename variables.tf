# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
variable "primary_region" {
  description = "The primary region for the terraform state bucket."
  type        = string
}

variable "state_bucket_prefix" {
  description = "The prefix for the account-regional terraform state bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z-]+$", var.state_bucket_prefix))
    error_message = "Variable state_bucket_prefix may only contain lowercase letters and hyphens."
  }

  validation {
    condition     = length(var.state_bucket_prefix) <= 24
    error_message = "Variable state_bucket_prefix must be 24 characters or less."
  }
}

# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
variable "bucket_encryption_keys" {
  default     = {}
  description = "Optional KMS keys to use for S3 terraform state bucket encryption, keyed by deployment region."
  type        = map(string)

  validation {
    condition = (
      var.secondary_region == null ||
      contains(keys(var.bucket_encryption_keys), var.primary_region) ==
      contains(keys(var.bucket_encryption_keys), var.secondary_region)
    )
    error_message = "When using a backup region, provide KMS keys for both regions or neither."
  }
}

variable "secondary_region" {
  default     = null
  description = "The secondary region for the terraform state bucket."
  type        = string

  validation {
    condition     = var.secondary_region != var.primary_region
    error_message = "secondary_region must differ from primary_region (both are \"${var.primary_region}\")."
  }
}

variable "tags" {
  default     = {}
  description = "Additional tags to merge into module tags."
  type        = map(string)
}
