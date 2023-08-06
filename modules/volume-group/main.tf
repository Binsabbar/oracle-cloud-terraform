resource "oci_core_volume_group" "create_volume_groups" {
  for_each = { for index, volume_group in var.volume_groups : index => volume_group }

  availability_domain = var.volume_group_availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name}-volume-group"
  backup_policy_id    = var.backup_policy_id
  defined_tags        = var.defined_tags
  freeform_tags       = var.freeform_tags

  source_details {
    type                    = each.value.type
    volume_ids              = each.value.volume_ids
    volume_group_backup_id  = each.value.volume_group_backup_id
    volume_group_id         = each.value.volume_group_id
    volume_group_replica_id = each.value.volume_group_replica_id
  }

  dynamic "volume_group_replicas" {
    for_each = each.value.volume_group_replicas != null ? [1] : []

    content {
      availability_domain = each.value.volume_group_replicas.availability_domain
      display_name        = each.value.volume_group_replicas.display_name
    }
  }
}