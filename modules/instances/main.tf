locals {
  flattened_primary_vnic_secondry_ips = flatten([
    for k, instance in var.instances : [
      for kk, secondry_ip in instance.config.primary_vnic.secondry_ips : {
        instance_key    = k
        secondry_ip_key = kk
        name            = secondry_ip.name
        ip_address      = secondry_ip.ip_address
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
        for ip_key, secondry_ip in vnic.secondry_ips : {
          instance_key    = instance_key
          vnic_key        = vnic_key
          secondry_ip_key = ip_key
          name            = secondry_ip.name
          ip_address      = secondry_ip.ip_address
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
  }

  create_vnic_details {
    subnet_id                 = each.value.config.subnet.id
    assign_public_ip          = each.value.config.subnet.prohibit_public_ip_on_vnic == false
    display_name              = "${each.key}Vnic"
    hostname_label            = each.key
    nsg_ids                   = each.value.config.network_sgs_ids
    skip_source_dest_check    = false
    assign_private_dns_record = true
    private_ip                = each.primary_vnic.primary_private_ip
  }

  source_details {
    source_type             = "image"
    source_id               = each.value.config.image_id
    boot_volume_size_in_gbs = each.value.volume_size
  }
}

# Getting Primary Initial Private IP ID for instance
data "oci_core_private_ips" "private_ips_by_ip_address" {
  for_each   = var.instances
  ip_address = oci_core_instance.instances[each.key].private_ip
}

resource "oci_core_private_ip" "primary_vnic_additional_ips" {
  for_each = { for v in local.flattened_primary_vnic_secondry_ips : "${v.instance_key}:${v.secondry_ip_key}" => v }

  display_name = each.value.name
  ip_address   = each.value.ip_address
  vnic_id      = data.oci_core_private_ips.private_ips_by_ip_address[each.value.instance_key].vnic_id
}

# Secondary VNICs
resource "oci_core_vnic_attachment" "secondary_vnic_attachment" {
  for_each     = { for v in local.flattened_secondary_vnics : "${v.instance_key}:${v.vnic_key}" => v }
  display_name = each.key
  create_vnic_details {
    assign_private_dns_record = true
    display_name              = each.value.vnic_key
    hostname_label            = each.value.vnic.hostname_label
    nsg_ids                   = each.value.vnic.nsg_ids
    private_ip                = each.value.vnic.primary_ip
    skip_source_dest_check    = each.value.vnic.skip_source_dest_check
    subnet_id                 = each.value.vnic.subnet_id
  }

  instance_id = oci_core_instance.instances[each.value.instance_key].id
}

resource "oci_core_private_ip" "secondary_vnic_additional_ips" {
  for_each = { for v in local.flattened_secondary_vnic_secondary_ips : "${v.instance_key}:${v.vnic_key}:${v.secondry_ip_key}" => v }

  display_name = each.value.name
  ip_address   = each.value.ip_address
  vnic_id      = oci_core_vnic_attachment.secondary_vnic_attachment["${v.instance_key}:${v.vnic_key}"].vnic_id
}
