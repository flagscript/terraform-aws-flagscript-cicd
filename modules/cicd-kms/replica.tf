resource "aws_kms_replica_key" "replica_kms_key" {
  for_each                           = toset(var.replica_regions)
  region                             = each.key
  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = var.deletion_window_in_days
  description                        = "${var.key_name} cicd kms key."
  enabled                            = var.enable_key
  primary_key_arn                    = aws_kms_key.primary_kms_key.arn
  tags = merge(
    local.common_tags,
    {
      "Name" = var.key_name
    }
  )
}

data "aws_iam_policy_document" "replica_kms_key_policy_document" {
  source_policy_documents = [
    data.aws_iam_policy_document.account_use_policy_document.json,
  ]
}

resource "aws_kms_key_policy" "replica_kms_key_policy" {
  for_each = toset(var.replica_regions)
  region   = each.key
  key_id   = aws_kms_replica_key.replica_kms_key[each.key].key_id
  policy   = data.aws_iam_policy_document.replica_kms_key_policy_document.json
}

resource "aws_kms_alias" "replica_kms_key_alias" {
  for_each      = toset(var.replica_regions)
  region        = each.key
  name          = "alias/${var.key_name}"
  target_key_id = aws_kms_replica_key.replica_kms_key[each.key].key_id
}
