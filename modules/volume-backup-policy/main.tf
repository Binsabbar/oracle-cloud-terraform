resource "oci_core_volume_backup_policy" "create_volume_backup_policy" {
  compartment_id     = var.compartment_id
  display_name       = var.name
  defined_tags       = var.defined_tags
  freeform_tags      = var.tags
  destination_region = var.destination_region

  dynamic "schedules" {
    for_each = var.backup_schedules

    content {
      backup_type       = schedules.value.backup_type
      period            = schedules.value.period
      retention_seconds = schedules.value.retention_seconds
      hour_of_day       = schedules.value.hour_of_day
      time_zone         = schedules.value.time_zone
      day_of_month      = schedules.value.day_of_month
      day_of_week       = schedules.value.day_of_week
      month             = schedules.value.month
      offset_seconds    = schedules.value.offset_seconds
      offset_type       = schedules.value.offset_type
    }
  }
}
