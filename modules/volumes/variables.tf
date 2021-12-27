variable "backup_policies" {
  type = map(object({
    compartment_id     = string
    name               = string
    destination_region = string
    schedules = map(object({
      backup_type       = string
      period            = string
      retention_seconds = number
      optionals         = map(string)
      # day_of_month 
      # day_of_week
      # hour_of_day
      # month
      # time_zone
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for k, v in var.backup_policies : [
        for kk, schedule in v.schedules : [
          for option in keys(schedule.optionals) : contains(["day_of_month", "day_of_week", "hour_of_day", "month", "zone"], option)
        ]
      ]
    ]))
    error_message = "The var.backup_policies.*.schedules.optionals accepts \"day_of_month\", \"day_of_week\", \"hour_of_day\", \"month\", \"offset_seconds\", \"offset_type\", \"zone\"."
  }
}

variable "volumes" {
  type = map(object({
    name                                = string
    compartment_id                      = string
    availability_domain                 = string
    size_in_gbs                         = string
    disable_replicas                    = bool
    reference_to_backup_policy_key_name = string # The name of the key in var.backup_policies
    cross_ad_replicas = map(object({
      destination_availability_domain = string
      replica_name                    = string
    }))
    source_volume = map(string)
    # id   = string
    # type = string
    instances_attachment = map(object({
      instance_id  = string
      is_shareable = bool
      optionals    = map(string)
      # type = string
      # is_read_only = bool
      # is_pv_encryption_in_transit_enabled = bool
      # encryption_in_transit_type = string
      # use_chap = bool
    }))
    optionals = map(string)
    # kms_id = string
    # auto_tuned = bool
    # vpus_per_gb = number
  }))

  validation {
    condition     = alltrue(flatten([for k, v in var.volumes : [for source_volume_key in keys(v.source_volume) : contains(["id", "type"], source_volume_key)]]))
    error_message = "The volumes.*.source_volume must be map consisting of the following two keys \"id\" and \"type\"."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.volumes : [
        for i_k, i_v in v.instances_attachment : [
        for option in keys(i_v.optionals) : contains(["type", "is_read_only", "is_pv_encryption_in_transit_enabled", "encryption_in_transit_type", "use_chap"], option)]
      ]
    ]))
    error_message = "The volumes.*.instnaces_attachment.*.optionals accepts \"type\", \"is_read_only\", \"is_pv_encryption_in_transit_enabled\", \"encryption_in_transit_type\", \"use_chap\"."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.volumes : [
        for option in keys(v.optionals) : contains(["kms_id", "auto_tuned", "vpus_per_gb"], option)
      ]
    ]))
    error_message = "The volumes.*.optionals accepts \"kms_id\", \"auto_tuned\", \"vpus_per_gb\"."
  }
}
