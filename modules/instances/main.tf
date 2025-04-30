locals {
  flattened_primary_vnic_secondary_ips = flatten([
    for k, instance in var.instances : [
      for kk, secondary_ip in instance.config.primary_vnic.secondary_ips : {
        instance_key     = k
        secondary_ip_key = kk
        name             = secondary_ip.name
        ip_address       = secondary_ip.ip_address
      }
    ]
  ])

  flattened_secondary_vnics = flatten([
    for instance_key, instance in var.instances : [
      for vnic_key, vnic in instance.secondary_vnics : {
        instance_key = instance_key
        vnic_key     = vnic_key
        vnic         = vnic
      }
    ]
  ])

  flattened_secondary_vnic_secondary_ips = flatten([
    for instance_key, instance in var.instances : [
      for vnic_key, vnic in instance.secondary_vnics : [
        for ip_key, secondary_ip in vnic.secondary_ips : {
          instance_key     = instance_key
          vnic_key         = vnic_key
          secondary_ip_key = ip_key
          name             = secondary_ip.name
          ip_address       = secondary_ip.ip_address
        }
      ]
    ]
  ])
}

resource "oci_core_instance" "instances" {
  for_each = var.instances

  availability_domain  = each.value.availability_domain_name
  fault_domain         = each.value.fault_domain_name
  compartment_id       = each.value.compartment_id
  shape                = each.value.config.shape
  display_name         = each.value.name
  preserve_boot_volume = lookup(each.value.optionals, "preserve_boot_volume", true)
  state                = each.value.state
  metadata = {
    ssh_authorized_keys = each.value.autherized_keys
    user_data           = lookup(each.value.optionals, "user_data", null)
  }

  dynamic "shape_config" {
    for_each = length(each.value.config.flex_shape_config) == 2 ? [1] : []
    content {
      memory_in_gbs = each.value.config.flex_shape_config.memory_in_gbs
      ocpus         = each.value.config.flex_shape_config.ocpus
    }
  }

  availability_config {
    is_live_migration_preferred = each.value.config.availability_config.is_live_migration_preferred
    recovery_action             = each.value.config.availability_config.recovery_action
  }

  lifecycle {
    ignore_changes = [
      metadata["user_data"]
    ]
  }

  create_vnic_details {
    subnet_id                 = each.value.config.subnet.id
    assign_public_ip          = each.value.config.subnet.prohibit_public_ip_on_vnic == false
    display_name              = "${each.key}Vnic"
    hostname_label            = each.key
    nsg_ids                   = each.value.config.network_sgs_ids
    skip_source_dest_check    = lookup(each.value.optionals, "skip_source_dest_check", false)
    assign_private_dns_record = true
    private_ip                = each.value.config.primary_vnic.primary_ip
    assign_ipv6ip             = each.value.ipv6
  }

  dynamic "source_details" {
    for_each = contains(keys(each.value.optionals), "boot_volume_id") && contains(keys(each.value.optionals), "boot_source_type") ? [1] : []
    content {
      source_type             = lookup(each.value.optionals, "boot_source_type")
      source_id               = lookup(each.value.optionals, "boot_volume_id")
      boot_volume_size_in_gbs = each.value.volume_size
    }
  }
  dynamic "source_details" {
    for_each = contains(keys(each.value.optionals), "boot_volume_id") && contains(keys(each.value.optionals), "boot_source_type") ? [] : [1]
    content {
      source_type             = "image"
      source_id               = each.value.config.image_id
      boot_volume_size_in_gbs = each.value.volume_size
    }
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    dynamic "plugins_config" {
      for_each = each.value.agent_plugins

      content {
        desired_state = plugins_config.value.is_enabled ? "ENABLED" : "DISABLED"
        name          = plugins_config.value.name
      }
    }
  }
}

# Getting Primary Initial Private IP for an instance
data "oci_core_private_ips" "primary_vnic_primary_private_ip" {
  for_each   = var.instances
  subnet_id  = each.value.config.subnet.id
  ip_address = oci_core_instance.instances[each.key].private_ip
}

resource "oci_core_private_ip" "primary_vnic_additional_ips" {
  for_each = { for v in local.flattened_primary_vnic_secondary_ips : "${v.instance_key}:primary_vnic:${v.secondary_ip_key}" => v }

  display_name = each.value.name
  ip_address   = each.value.ip_address
  vnic_id      = [for ip in data.oci_core_private_ips.primary_vnic_primary_private_ip[each.value.instance_key].private_ips : ip if ip.is_primary][0].vnic_id
}

# Secondary VNICs
resource "oci_core_vnic_attachment" "secondary_vnic_attachment" {
  for_each     = { for v in local.flattened_secondary_vnics : "${v.instance_key}:${v.vnic_key}" => v }
  display_name = each.key
  create_vnic_details {
    assign_private_dns_record = true
    display_name              = each.value.vnic.name
    private_ip                = each.value.vnic.primary_ip == "" ? null : each.value.vnic.primary_ip
    nsg_ids                   = each.value.vnic.nsg_ids
    subnet_id                 = each.value.vnic.subnet_id
    hostname_label            = each.value.vnic.hostname_label
    skip_source_dest_check    = each.value.vnic.skip_source_dest_check
    assign_ipv6ip             = each.value.vnic.ipv6
  }

  instance_id = oci_core_instance.instances[each.value.instance_key].id
}

resource "oci_core_private_ip" "secondary_vnic_additional_ips" {
  for_each = { for v in local.flattened_secondary_vnic_secondary_ips : "${v.instance_key}:${v.vnic_key}:${v.secondary_ip_key}" => v }

  display_name = each.value.name
  ip_address   = each.value.ip_address
  vnic_id      = oci_core_vnic_attachment.secondary_vnic_attachment["${each.value.instance_key}:${each.value.vnic_key}"].vnic_id
}

data "oci_core_private_ips" "secondary_vnic_attachment_ips" {
  for_each = { for v in local.flattened_secondary_vnics : "${v.instance_key}:${v.vnic_key}" => v }
  vnic_id  = oci_core_vnic_attachment.secondary_vnic_attachment[each.key].vnic_id
}

// Backup Policy
resource "oci_core_volume_backup_policy" "boot_volume_backup_policy" {
  for_each = var.boot_volume_backup_policies

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
resource "oci_core_volume_backup_policy_assignment" "boot_volume_backup_policy_assignment" {
  for_each = { for k, v in var.instances : k => v if lookup(v.optionals, "reference_to_backup_policy_key_name", null) != null }

  asset_id  = oci_core_instance.instances[each.key].boot_volume_id
  policy_id = oci_core_volume_backup_policy.boot_volume_backup_policy[each.value.optionals.reference_to_backup_policy_key_name].id
}
