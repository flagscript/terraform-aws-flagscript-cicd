/**
 * # Basic example
 *
 * A single Terraform state bucket in `us-east-1`, encrypted with SSE-S3, plus the IAM
 * policy that grants access to it.
 *
 * ```bash
 * terraform init
 * terraform apply
 * ```
 *
 * Point other configurations at the bucket from the `terraform_state_bucket_name` output:
 *
 * ```hcl
 * terraform {
 *   backend "s3" {
 *     bucket       = "example-tfstate-123456789012-us-east-1-an"
 *     key          = "my-project/terraform.tfstate"
 *     region       = "us-east-1"
 *     encrypt      = true
 *     use_lockfile = true
 *   }
 * }
 * ```
 */

provider "aws" {
  region = "us-east-1"
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  primary_region      = "us-east-1"
  state_bucket_prefix = "example"

  tags = {
    Environment = "example"
  }
}
