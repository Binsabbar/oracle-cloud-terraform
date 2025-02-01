// DRG
resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_id
  display_name   = var.drg_display_name
}


// ATTACHMENT
resource "oci_core_drg_attachment" "drg_attachment" {
  for_each = var.drg_attachment

  drg_id       = oci_core_drg.drg.id
  display_name = var.drg_attachment.name

  drg_route_table_id = lookup(var.drg_attachment.optionals, "drg_route_table_id", oci_core_drg.drg.default_drg_route_tables.vcn)
  network_details {
    id   = oci_core_vcn.vcn.id
    type = var.drg_attachment.network_details_type

    #Optional
    ids            = var.drg_attachment_network_details_id
    route_table_id = oci_core_route_table.route_table.id
    vcn_route_type = var.drg_attachment_network_details_vcn_route_type
  }
}