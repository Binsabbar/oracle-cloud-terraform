// DRG
resource "oci_core_drg" "drg" {
  display_name   = var.drg.name
  compartment_id = var.drg.compartment_id
}


// ATTACHMENT
resource "oci_core_drg_attachment" "drg_attachment" {
  for_each           = var.drg_attachment
  drg_id             = oci_core_drg.drg.id
  display_name       = var.drg_attachment.name
  drg_route_table_id = lookup(var.drg_attachment.optionals, "drg_route_table_id", oci_core_drg.drg.default_drg_route_tables.vcn)
  network_details {
    id             = var.drg_attachment.id
    type           = var.drg_attachment.network_details_type
    route_table_id = lookup(var.drg_attachment.optionals, "route_table_id", null)
    vcn_route_type = lookup(var.drg_attachment.optionals, "vcn_route_type", null)
  }
}