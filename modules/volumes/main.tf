variable "volumes" {
  type = map(object({
    name = string
    compartment_id = string
    availability_domain = string
    size_in_gbs = string
    disable_replicas = bool
    cross_ad_replicas = map(object({
      destination_availability_domain = string
      replica_name = string
    }))
    cloned  = bool
    source_volume = list(object({
      id = string
      type = string
    }))
    optionals = map(string)
    # kms_id
    # auto_tuned
    # vpus_per_gb
  }))

  
  validation {
    condition = alltrue([
      for k, v in var.volumes:
      length(v.source_volume) < 2
    ])
    error_message = "The volumes.*.source_volume cannot contain more than 1 value."
  }
  
  validation {
    condition = alltrue(flatten([
      for k, v in var.volumes: [
        for option in keys(v.optionals): contains(["kms_id", "auto_tuned", "vpus_per_gb"], option)
      ]
    ]))
    error_message = "The volumes.*.optionals accepts \"kms_id\", \"auto_tuned\", \"vpus_per_gb\"."
  }
}

// Volume
resource "oci_core_volume" "volume" {
    for_each = var.volumes

    compartment_id = each.value.compartment_id
    availability_domain = each.value.availability_domain
    display_name = each.value.name
    size_in_gbs = each.value.size_in_gbs
    
    kms_key_id = lookup(each.value.optionals, "kms_id", "")
    is_auto_tune_enabled = lookup(each.value.optionals, "auto_tuned", "true")
    vpus_per_gb = lookup(each.value.optionals, "vpus_per_gb", "20")
    
    block_volume_replicas_deletion = each.value.disable_replicas
    dynamic "block_volume_replicas" {
      for_each = each.value.disable_replicas ? {} : each.value.cross_region_replica
      content {
        availability_domain = block_volume_replicas.value.replica_region
        display_name = block_volume_replicas.value.replica_name
      }
    }
    
    dynamic "source_details" {
      for_each = each.value.cloned ? each.value.source_volume:[]
      content {
        id = source_details.value.id
        type = source_details.value.type
      }
    }
}



// Attachment 
# resource "oci_core_volume_attachment" "volume_paravirtualized_attachment" {
#     attachment_type = value.attachment_type
#     instance_id = each.value.instance_id
#     volume_id = oci_core_volume.volume.id
#     display_name = each.key
#     is_read_only = each.value.is_read_only
#     is_shareable = each.value.is_shareable    
#     is_pv_encryption_in_transit_enabled =  each.value.is_pv_encryption_in_transit_enabled
# }

# resource "oci_core_volume_attachment" "volume_attachment" {
#     attachment_type = value.attachment_type
#     instance_id = each.value.instance_id
#     volume_id = oci_core_volume.volume.id
#     display_name = each.key
#     is_read_only = each.value.is_read_only
#     is_shareable = each.value.is_shareable
#     encryption_in_transit_type = lookup("", "NONE")
#     use_chap = each.value.use_chap
# }

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