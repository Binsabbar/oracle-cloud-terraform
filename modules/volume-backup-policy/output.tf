output "backup_policy" {
  description = "Volume backup policy"
  value       = oci_core_volume_backup_policy.create_volume_backup_policy
}

output "backup_policy_id" {
  description = "Volume backup policy ID"
  value       = oci_core_volume_backup_policy.create_volume_backup_policy.id
}
