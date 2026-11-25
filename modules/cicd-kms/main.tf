resource "aws_kms_key" "primary_kms_key" {
  region                             = var.primary_region
  bypass_policy_lockout_safety_check = false
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  deletion_window_in_days            = var.deletion_window_in_days
  description                        = "${var.key_name} cicd kms key."
  enable_key_rotation                = var.enable_key_rotation
  is_enabled                         = var.enable_key
  key_usage                          = "ENCRYPT_DECRYPT"
  multi_region                       = true
  tags = merge(
    local.common_tags,
    {
      "Name" = var.key_name
    }
  )
}

data "aws_iam_policy_document" "primary_kms_key_policy_document" {

  source_policy_documents = [
    data.aws_iam_policy_document.account_use_policy_document.json,
  ]
}

resource "aws_kms_key_policy" "primary_kms_key_policy" {
  region = var.primary_region
  key_id = aws_kms_key.primary_kms_key.key_id
  policy = data.aws_iam_policy_document.primary_kms_key_policy_document.json
}

resource "aws_kms_alias" "primary_kms_key_alias" {
  region        = var.primary_region
  name          = "alias/${var.key_name}"
  target_key_id = aws_kms_key.primary_kms_key.key_id
}
