locals {
  flatten_rules = merge([
    for k, route in var.drg.route_tables : {
      for kr, rule in route.rules : "${k}-${kr}" => merge(rule, { route_table_key = k })
    }
  ]...)

  vcn_attachments_keys      = { for key, value in oci_core_drg_attachment.drg_attachments : key => { id = value.id } }
  none_vcn_attachments_keys = { for key, value in oci_core_drg_attachment_management.none_vcn_drg_attachment : key => { id = value.id } }
  attachments_ids           = merge(local.vcn_attachments_keys, local.none_vcn_attachments_keys)

  default_drg_route_table_ids = {
    "VCN"                       = oci_core_drg.drg.default_drg_route_tables[0].vcn
    "IPSEC_TUNNEL"              = oci_core_drg.drg.default_drg_route_tables[0].ipsec_tunnel
    "REMOTE_PEERING_CONNECTION" = oci_core_drg.drg.default_drg_route_tables[0].remote_peering_connection
    "VIRTUAL_CIRCUIT"           = oci_core_drg.drg.default_drg_route_tables[0].virtual_circuit
  }
}

// DRG
resource "oci_core_drg" "drg" {
  display_name   = var.drg.name
  compartment_id = var.compartment_id
}


// ATTACHMENT
resource "oci_core_drg_attachment" "drg_attachments" {
  for_each = var.drg.vcn_attachments

  drg_id             = oci_core_drg.drg.id
  display_name       = each.value.name
  drg_route_table_id = each.value.drg_route_table_key != "" ? oci_core_drg_route_table.drg_route_table[each.value.drg_route_table_key].id : local.default_drg_route_table_ids["VCN"]

  network_details {
    id             = each.value.vcn_id
    type           = "VCN"
    route_table_id = each.value.route_table_id
    vcn_route_type = each.value.vcn_route_type
  }
}

resource "oci_core_drg_attachment_management" "none_vcn_drg_attachment" {
  for_each = var.drg.none_vcn_attachments_managements

  drg_id          = oci_core_drg.drg.id
  display_name    = each.value.name
  attachment_type = each.value.type
  network_id      = each.value.network_id

  compartment_id     = each.value.compartment_id != "" ? each.value.compartment_id : var.compartment_id
  drg_route_table_id = each.value.drg_route_table_key != "" ? oci_core_drg_route_table.drg_route_table[each.value.drg_route_table_key].id : local.default_drg_route_table_ids[each.value.type]
}

// ROUTE TABLE
resource "oci_core_drg_route_table" "drg_route_table" {
  for_each = var.drg.route_tables

  drg_id       = oci_core_drg.drg.id
  display_name = each.value.name
}

resource "oci_core_drg_route_table_route_rule" "drg_route_table_route_rule" {
  for_each = local.flatten_rules

  drg_route_table_id         = oci_core_drg_route_table.drg_route_table[each.value.route_table_key].id
  destination                = each.value.destination
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = local.attachments_ids[each.value.next_hop_drg_attachment_key].id
}

// REMOTE PEERING CONNECTION
resource "oci_core_remote_peering_connection" "remote_peering_connection" {
  for_each = var.drg.remote_peering_connections

  compartment_id   = var.compartment_id
  drg_id           = oci_core_drg.drg.id
  display_name     = each.value.name
  peer_id          = try(each.value.peer_connection.peer_id, null)
  peer_region_name = try(each.value.peer_connection.peer_region_name, null)
}

resource "oci_core_drg_attachment_management" "rpc_drg_attachment" {
  for_each = var.drg.remote_peering_connections

  drg_id          = oci_core_drg.drg.id
  compartment_id  = var.compartment_id
  attachment_type = "REMOTE_PEERING_CONNECTION"

  display_name       = each.value.name
  network_id         = oci_core_remote_peering_connection.remote_peering_connection[each.key].id
  drg_route_table_id = each.value.drg_route_table_key != "" ? oci_core_drg_route_table.drg_route_table[each.value.drg_route_table_key].id : local.default_drg_route_table_ids["REMOTE_PEERING_CONNECTION"]

  lifecycle {
    replace_triggered_by = [oci_core_remote_peering_connection.remote_peering_connection[each.key].id]
  }
}

