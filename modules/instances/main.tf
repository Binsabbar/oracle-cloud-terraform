resource "oci_core_instance" "instances" {
  for_each = var.instances

  availability_domain  = each.value.availability_domain_name
  fault_domain         = each.value.fault_domain_name
  compartment_id       = each.value.compartment_id
  shape                = each.value.config.shape
  display_name         = each.value.name
  preserve_boot_volume = true
  state                = each.value.state
  metadata = {
    ssh_authorized_keys = each.value.autherized_keys
  }

  create_vnic_details {
    subnet_id              = each.value.config.subnet.id
    assign_public_ip       = each.value.config.subnet.prohibit_public_ip_on_vnic == false
    display_name           = "${each.key}Vnic"
    hostname_label         = each.key
    nsg_ids                = each.value.config.network_sgs_ids
    skip_source_dest_check = false
  }

  source_details {
    source_type             = "image"
    source_id               = each.value.config.image_id
    boot_volume_size_in_gbs = each.value.volume_size
  }
}