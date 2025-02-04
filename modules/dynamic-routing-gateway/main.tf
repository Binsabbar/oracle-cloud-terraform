// DRG
resource "oci_core_drg" "drg" {
  display_name   = var.drg.name
  compartment_id = var.compartment_id
}


// ATTACHMENT
resource "oci_core_drg_attachment" "drg_attachments" {
  for_each           = { for k, v in var.drg.attachments : k => v if v != null }
  drg_id             = oci_core_drg.drg.id
  display_name       = each.key
  drg_route_table_id = lookup(each.value.optionals, "drg_route_table_id", oci_core_drg.drg.default_drg_route_tables[0].vcn)
  network_details {
    id             = each.value.vcn_id
    type           = "VCN"
    route_table_id = lookup(each.value.optionals, "route_table_id", null)
    vcn_route_type = lookup(each.value.optionals, "vcn_route_type", null)
  }
}