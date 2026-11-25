output "key_arns" {
  description = "Map of regions to their respective cicd kms key arns."
  value = merge(
    {
      (aws_kms_key.primary_kms_key.region) = aws_kms_key.primary_kms_key.arn
    },
    {
      for replica in aws_kms_replica_key.replica_kms_key : replica.region => replica.arn
    }
  )
}

output "key_ids" {
  description = "Map of regions to their respective cicd kms key ids."
  value = merge(
    {
      (aws_kms_key.primary_kms_key.region) = aws_kms_key.primary_kms_key.id
    },
    {
      for replica in aws_kms_replica_key.replica_kms_key : replica.region => replica.id
    }
  )
}
