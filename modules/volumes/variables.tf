variable "volumes" {
  type = map(object({
    name                = string
    compartment_id      = string
    availability_domain = string
    size_in_gbs         = string
    disable_replicas    = bool
    cross_ad_replicas = map(object({
      destination_availability_domain = string
      replica_name                    = string
    }))
    cloned = bool
    source_volume = list(object({
      id   = string
      type = string
    }))
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
    condition = alltrue([
      for k, v in var.volumes :
      length(v.source_volume) < 2
    ])
    error_message = "The volumes.*.source_volume cannot contain more than 1 value."
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
