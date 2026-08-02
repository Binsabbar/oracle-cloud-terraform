
locals {
  default_primary_config = {
    primary_ip    = ""
    secondary_ips = {}
  }
}

variable "boot_volume_backup_policies" {
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

  default = {}

  validation {
    condition = alltrue(flatten([
      for k, v in var.boot_volume_backup_policies : [
        for kk, schedule in v.schedules : [
          for option in keys(schedule.optionals) : contains(["day_of_month", "day_of_week", "hour_of_day", "month", "zone"], option)
        ]
      ]
    ]))
    error_message = "The var.boot_volume_backup_policies.*.schedules.optionals accepts \"day_of_month\", \"day_of_week\", \"hour_of_day\", \"month\", \"offset_seconds\", \"offset_type\", \"zone\"."
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

variable "instances" {
  type = map(object({
    name                     = string
    availability_domain_name = string
    fault_domain_name        = string
    compartment_id           = string
    volume_size              = number
    state                    = string
    autherized_keys          = string
    ipv6                     = optional(bool, false)
    freeform_tags            = optional(map(string), null)
    defined_tags             = optional(map(string), null)
    hostname                 = optional(string, "")
    config = object({
      shape             = string
      flex_shape_config = map(string)
      image_id          = string
      network_sgs_ids   = list(string)
      subnet = object({
        id                         = string,
        prohibit_public_ip_on_vnic = bool
      })
      primary_vnic = object({
        primary_ip = string
        secondary_ips = map(object({
          name       = string
          ip_address = string
        }))
      })
      availability_config = object({
        recovery_action             = string,
        is_live_migration_preferred = bool
      })
    })
    secondary_vnics = map(object({
      name                   = string
      primary_ip             = string
      subnet_id              = string
      nsg_ids                = list(string)
      skip_source_dest_check = bool
      hostname_label         = string
      ipv6                   = optional(bool, false)
      secondary_ips = map(object({
        name       = string
        ip_address = string
      }))
    }))
    agent_plugins = optional(
      map(object({
        name       = string
        is_enabled = bool
      })),
      {}
    )
    optionals = map(any)
    # preserve_boot_volume =  bool (true)
    # boot_volume_id = string
    # boot_source_type = string
    # user_data        = string
    # reference_to_backup_policy_key_name = string # The name of the key in var.boot_volume_backup_policies
  }))

  description = <<EOF
    map of objects that represent instances to create. The key name is the instance name that is used for FQDN
    name                    : the name of instance
    availability_domain_name: the name of the availability domain to create instance in
    fault_domain_name       : the name of the fault domain in the availability domain to create instance in
    compartment_id          : ocid of the compartment
    volume_size             : the initial boot volume size in GB
    state                   : RUNNING or STOPPED
    autherized_keys         : single string containing the SSH-RSA keys seperated by \n
    config                  : object of instance configuration
      shape           : name of the VM shape to be used
      flex_shape_config     : customize number of ocpus and memory when using Flex Shape
      image_id        : ocid of the boot image
      network_sgs_ids : list network security groups ids to be applied to the main interface
      subnet          : object for the subnet configuration
        id                         : ocid of the subnet
        prohibit_public_ip_on_vnic : whether to create public IP or not if located in public subnet, set to false if not
      primary_vnic : object for primary VNIC configuration
        primary_ip    : custom initial IP. If left empty, oci will create IP dynamically.
        secondary_ips : map of objects for secondary IP configuration
          name         : the name of IP
          ip_address   : custom IP that must be in the same subnet above of VNIC. If left empty, oci will create IP dynamically
      availability_config :  object for VM migration configuration
        recovery_action : The lifecycle state for an instance when it is recovered after infrastructure maintenance.
        is_live_migration_preferred : Whether to live migrate supported VM instances to a healthy physical VM host without disrupting.

    secondary_vnics: map of object for secondary VNIC configuration
      name       = the name of VNIC
      primary_ip =  custom initial IP. If left empty, oci will create IP dynamically.
      subnet_id  = subnet id for creating the VNIC in
      nsg_ids    = list network security groups ids to be applied to the VNIC
      skip_source_dest_check = bool (false)
      hostname_label         = string (null)
      secondary_ips = map of objects for secondary IP configuration
        name       = string
        ip_address = string
    optionals : set of key/value map that can be used for customise default values.
      preserve_boot_volume                     : whether to keep boot volume after delete or not
      boot_volume_id                           : when need to boot from an existing boot volume, set this value to a volume ID
      boot_source_type                         : when need to change boot type: `image` or `bootVolume`
      reference_to_backup_policy_key_name      : reference to policy key name in the input `var.boot_volume_backup_policies`. If empty, no backup will be scheduled
  EOF

  validation {
    condition = alltrue(flatten([
      for k, v in var.instances : [
        for key in keys(v.config.flex_shape_config) :
        contains(["ocpus", "memory_in_gbs"], key)
      ]
    ]))
    error_message = "The instances.*.config.flex_shape_config accepts only \"ocpus\", \"memory_in_gbs\"."
  }
}
