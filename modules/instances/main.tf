locals {
  flattened_primary_vnic_secondry_ips = flatten([
    for k, instance in var.instances: [
      for kk, secondry_ip in instance.config.primary_vnic.secondry_ips: {
        instance_key = k
        secondry_ip_key = kk
        name         = secondry_ip.name
        ip_address   = secondry_ip.ip_address
      }
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
    skip_source_dest_check    =  false
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
  for_each = var.instances
  ip_address = oci_core_instance.instances[each.key].private_ip
}

resource "oci_core_private_ip" "primary_vnic_additional_ips" {
  for_each = { for v in local.flattened_primary_vnic_secondry_ips: "${v.instance_key}-${v.secondry_ip_key}" => v }
  
  display_name = each.value.name
  hostname_label = each.value.name
  ip_address = each.value.ip_address
  vnic_id = data.oci_core_private_ips.private_ips_by_ip_address[each.value.instance_key].vnic_id
}