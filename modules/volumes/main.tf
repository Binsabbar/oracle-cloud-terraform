locals {
  instance_volume_attachments = merge([
    for vol_k, vol_v in var.volumes : {
      for attch_k, attach_v in vol_v.instances_attachment : "${vol_k}-${attch_k}" => merge(attach_v, { volume_key = vol_k })
    }
  ]...)

  does_reference_to_backup_policy_key_name_exist = alltrue([ for k, v in var.volumes : v.reference_to_backup_policy_key_name != null? contains(keys(var.backup_policies), v.reference_to_backup_policy_key_name):true ])
}

// Error Checking if reference_to_backup_policy_key_name exists in var.backup_policies (work around described here https://github.com/hashicorp/terraform/issues/15469#issuecomment-814789329)
resource "null_resource" "does_reference_to_backup_policy_key_name_exist" {
  count = local.does_reference_to_backup_policy_key_name_exist ? 0 : "ERROR: volumes.*.reference_to_backup_policy_key_name must exist in var.backup_policies"
}

// Volume
resource "oci_core_volume" "volume" {
  for_each = var.volumes

  compartment_id      = each.value.compartment_id
  availability_domain = each.value.availability_domain
  display_name        = each.value.name
  size_in_gbs         = each.value.size_in_gbs

  kms_key_id           = lookup(each.value.optionals, "kms_id", "")
  is_auto_tune_enabled = lookup(each.value.optionals, "auto_tuned", "true")
  vpus_per_gb          = lookup(each.value.optionals, "vpus_per_gb", "20")

  block_volume_replicas_deletion = each.value.disable_replicas
  dynamic "block_volume_replicas" {
    for_each = each.value.disable_replicas ? {} : each.value.cross_region_replica
    content {
      availability_domain = block_volume_replicas.value.replica_region
      display_name        = block_volume_replicas.value.replica_name
    }
  }

  dynamic "source_details" {
    for_each = length(each.value.source_volume) != 0 ? [each.value.source_volume] : []
    content {
      id   = source_details.value.id
      type = source_details.value.type
    }
  }
}

// Attachment 
resource "oci_core_volume_attachment" "volume_attachment" {
  for_each = local.instance_volume_attachments

  display_name                        = each.key
  volume_id                           = oci_core_volume.volume[each.value.volume_key].id
  attachment_type                     = lookup(each.value.optionals, "type", "paravirtualized")
  instance_id                         = each.value.instance_id
  is_read_only                        = lookup(each.value.optionals, "is_read_only", "false")
  is_shareable                        = each.value.is_shareable
  is_pv_encryption_in_transit_enabled = lookup(each.value.optionals, "is_pv_encryption_in_transit_enabled", "false")
  encryption_in_transit_type          = lookup(each.value.optionals, "encryption_in_transit_type", "NONE")
  use_chap                            = lookup(each.value.optionals, "use_chap", "false")
}

# // Backup Policy
# resource "oci_core_volume_backup_policy" "volume_backup_policy" {
#     compartment_id = var.compartment_id
#     destination_region = var.volume_backup_policy_destination_region
#     display_name = var.volume_backup_policy_display_name
#     schedules {
#         backup_type = var.volume_backup_policy_schedules_backup_type
#         period = var.volume_backup_policy_schedules_period
#         retention_seconds = var.volume_backup_policy_schedules_retention_seconds

#         day_of_month = var.volume_backup_policy_schedules_day_of_month
#         day_of_week = var.volume_backup_policy_schedules_day_of_week
#         hour_of_day = var.volume_backup_policy_schedules_hour_of_day
#         month = var.volume_backup_policy_schedules_month
#         offset_seconds = var.volume_backup_policy_schedules_offset_seconds
#         offset_type = var.volume_backup_policy_schedules_offset_type
#         time_zone = var.volume_backup_policy_schedules_time_zone
#     }
# }


# // Policy Attachment
# resource "oci_core_volume_backup_policy_assignment" "volume_backup_policy_assignment" {
#     asset_id = oci_core_volume.test_volume.id
#     policy_id = oci_core_volume_backup_policy.test_volume_backup_policy.id
# }

# // Group
# resource "oci_core_volume_group" "test_volume_group" {
#     availability_domain = var.volume_group_availability_domain
#     compartment_id = var.compartment_id
#     display_name = var.volume_group_display_name
#     backup_policy_id = data.oci_core_volume_backup_policies.test_volume_backup_policies.volume_backup_policies.0.id
#     source_details {
#         type = "volumeIds"
#         volume_ids = [var.volume_group_source_id]
#     }
# }

# // Group backup
# resource "oci_core_volume_group_backup" "volume_group_backup" {
#     volume_group_id = oci_core_volume_group.test_volume_group.id
#     compartment_id = var.compartment_id
#     display_name = var.volume_group_backup_display_name
#     type = var.volume_group_backup_type
# }