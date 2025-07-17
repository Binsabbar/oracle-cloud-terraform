resource "oci_bastion_bastion" "bastion_hosts" {
  name                         = var.bastion_name
  compartment_id               = var.compartment_id
  target_subnet_id             = var.target_subnet_id
  bastion_type                 = "STANDARD"
  client_cidr_block_allow_list = var.allowed_ips
  max_session_ttl_in_seconds   = var.max_session_ttl_seconds


  lifecycle {
    ignore_changes = [bastion_type]
  }
}

resource "oci_bastion_session" "sessions" {
  for_each   = local.session_combinations_map
  bastion_id = oci_bastion_bastion.bastion_hosts.id

  key_details {
    public_key_content = var.ssh_public_keys[each.value.session.user]
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = each.value.target_id
    target_resource_operating_system_user_name = each.value.session.os_user
    target_resource_port                       = each.value.session.port
    target_resource_private_ip_address         = each.value.target_ip
  }

  session_ttl_in_seconds = each.value.session.time * 60
  display_name           = each.value.display_name

  lifecycle {
    create_before_destroy = true
  }
}
