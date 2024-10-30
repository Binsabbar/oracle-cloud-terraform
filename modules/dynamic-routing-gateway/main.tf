// create DRG
resource "oci_core_drg" "test_drg" {
    #Required
    compartment_id = var.compartment_id

    #Optional
    defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.drg_display_name
    freeform_tags = {"Department"= "Finance"}
}


// ATTACHMENT
resource "oci_core_drg_attachment" "test_drg_attachment" {
    #Required
    drg_id = oci_core_drg.test_drg.id

    #Optional
    defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.drg_attachment_display_name
    drg_route_table_id = oci_core_drg_route_table.test_drg_route_table.id
    freeform_tags = {"Department"= "Finance"}
    network_details {
        #Required
        id = oci_core_vcn.test_vcn.id
        type = var.drg_attachment_network_details_type

        #Optional
        id = var.drg_attachment_network_details_id
        route_table_id = oci_core_route_table.test_route_table.id
        vcn_route_type = var.drg_attachment_network_details_vcn_route_type
    }
}

// Route Table
resource "oci_core_drg_route_table" "test_drg_route_table" {
    #Required
    drg_id = oci_core_drg.test_drg.id

    #Optional
    defined_tags = {"Operations.CostCenter"= "42"}
    display_name = var.drg_route_table_display_name
    freeform_tags = {"Department"= "Finance"}
    import_drg_route_distribution_id = oci_core_drg_route_distribution.test_drg_route_distribution.id
    is_ecmp_enabled = var.drg_route_table_is_ecmp_enabled
}

resource "oci_core_drg_route_table_route_rule" "test_drg_route_table_route_rule" {
    #Required
    drg_route_table_id = oci_core_drg_route_table.test_drg_route_table.id
    destination = var.drg_route_table_route_rule_route_rules_destination
    destination_type = var.drg_route_table_route_rule_route_rules_destination_type
    next_hop_drg_attachment_id = oci_core_drg_attachment.test_drg_attachment.id

}