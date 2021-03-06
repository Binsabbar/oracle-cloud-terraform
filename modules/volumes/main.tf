locals {
  instance_volume_attachments = merge([
    for vol_k, vol_v in var.volumes : {
      for attch_k, attach_v in vol_v.instances_attachment : "${vol_k}-${attch_k}" => merge(attach_v, { volume_key = vol_k })
    }
  ]...)

  does_reference_to_backup_policy_key_name_exist = alltrue([for k, v in var.volumes : v.reference_to_backup_policy_key_name != null ? contains(keys(var.backup_policies), v.reference_to_backup_policy_key_name) : true])
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

// Volume Attachment to Instnace
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

// Backup Policy
resource "oci_core_volume_backup_policy" "volume_backup_policy" {
  for_each = var.backup_policies

  compartment_id     = each.value.compartment_id
  destination_region = each.value.destination_region
  display_name       = each.value.name

  dynamic "schedules" {
    for_each = each.value.schedules
    content {
      offset_seconds    = 0
      offset_type       = "STRUCTURED"
      backup_type       = schedules.value.backup_type
      period            = schedules.value.period
      retention_seconds = schedules.value.retention_seconds
      time_zone         = lookup(schedules.value.optionals, "time_zone", "UTC")
      hour_of_day       = lookup(schedules.value.optionals, "hour_of_day", 0)
      day_of_week       = lookup(schedules.value.optionals, "day_of_week", "MONDAY")
      day_of_month      = lookup(schedules.value.optionals, "day_of_month", 1)
      month             = lookup(schedules.value.optionals, "month", "JANUARY")
    }
  }
}


// Policy Attachment
resource "oci_core_volume_backup_policy_assignment" "volume_backup_policy_assignment" {
  for_each = { for volume_k, volume_v in var.volumes : volume_k => volume_v if volume_v.reference_to_backup_policy_key_name != null }

  asset_id  = oci_core_volume.volume[each.key].id
  policy_id = oci_core_volume_backup_policy.volume_backup_policy[each.value.reference_to_backup_policy_key_name].id
}