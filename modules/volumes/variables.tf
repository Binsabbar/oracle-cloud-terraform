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

  description = <<EOF
    compartment_id     : which compartment to create the volume in
    name               : policy name
    destination_region : Backup destination region for this policy
    schedules          : map of backup scheduling configuration
      backup_type       : type of the backup (INCREMENTAL, FULL)
      period            : backup frequency (ONE_DAY, ONE_WEEK, ONE_MONTH, ONE_YEAR)
      retention_seconds : for how long to keep the backup for?
      optionals         : map of extra optional schedules configuration 
        day_of_month (Default: `1`)
        day_of_week  (Default: `MONDAY`)
        hour_of_day  (Default: `0`)
        month        (Default: `JANUARY`)
        time_zone    (Default: `UTC`) : Support either `UTC` or `REGIONAL_DATA_CENTER_TIME`
  EOF
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
      # device = string
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
        for option in keys(i_v.optionals) : contains(["type", "is_read_only", "is_pv_encryption_in_transit_enabled", "encryption_in_transit_type", "use_chap", "device"], option)]
      ]
    ]))
    error_message = "The volumes.*.instnaces_attachment.*.optionals accepts \"type\", \"is_read_only\", \"is_pv_encryption_in_transit_enabled\", \"encryption_in_transit_type\", \"use_chap\", \"device\"."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.volumes : [
        for option in keys(v.optionals) : contains(["kms_id", "auto_tuned", "vpus_per_gb"], option)
      ]
    ]))
    error_message = "The volumes.*.optionals accepts \"kms_id\", \"auto_tuned\", \"vpus_per_gb\"."
  }

  description = <<EOF
    name                                : name of the oci volume
    compartment_id                      : which compartment to create the volume in
    availability_domain                 : in which availability domain to create the volume
    size_in_gbs                         : volume size in GB
    disable_replicas                    : wether to enable or disable replication of volume accross other availability domain
    reference_to_backup_policy_key_name : name of the backup policy key in var.backup_policies (Leave Empty is no backup is required)
    cross_ad_replicas                   : Map of replicas configuration. You can have multiple replication 
      destination_availability_domain : name of the availability domain
      replica_name                    : name of the replica 
    source_volume: map of source volume configuration
      id   : the ocid of the target source 
      type : type of the source (volume, bootvolume). Check OCI docs for supported types
    instances_attachment : map of instance attachements configurations
      instance_id  : ocid of the instance
      is_shareable : where to make this attachment shareable or not. Check OCI docs for sharable volumes
      optionals    : map of optional values to overwirte for instance attachments (leave empty to use default value {})
        type                                (Default: `paravirtualized`)                     
        is_read_only                        (Default: `false`)
        is_pv_encryption_in_transit_enabled (Default: `false`) 
        encryption_in_transit_type          (default: `NONE`)
        use_chap                            (Default: `false`)
        device                              (Default: `NONE`)
    optionals : map of optional values for volumes configuration (leave empty to use default value {})
      kms_id      (Default: '')
      auto_tuned  (Default: `true`)
      vpus_per_gb (Default: `20`)
  EOF
}
