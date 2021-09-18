resource "oci_core_vcn" "vcn" {
  cidr_block     = var.cidr_block
  compartment_id = var.compartment_id
  display_name   = var.name
  dns_label      = var.name
}

resource "oci_core_default_dhcp_options" "dhcp_options" {
  manage_default_resource_id = oci_core_vcn.vcn.default_dhcp_options_id
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
}

// Gateways
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = true
  display_name   = "defaultInternetGateway"
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "defaultNatGateway"
}


// Routes
resource "oci_core_default_route_table" "public_route_table" {
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id
  display_name               = "defaultRouteTable"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }

  dynamic "route_rules" {
    for_each = var.public_route_table_rules
    content {
      description       = route_rules.key
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity_id
    }
  }
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "defaultPrivateRouteTable"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }

  dynamic "route_rules" {
    for_each = var.private_route_table_rules
    content {
      description       = route_rules.key
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity_id
    }
  }
}

// Subnetting
resource "oci_core_subnet" "public_subnet" {
  for_each                   = var.public_subnets
  compartment_id             = var.compartment_id
  cidr_block                 = each.value.cidr_block
  prohibit_public_ip_on_vnic = false
  vcn_id                     = oci_core_vcn.vcn.id
  dhcp_options_id            = oci_core_default_dhcp_options.dhcp_options.id
  route_table_id             = lookup(each.value.optionals, "route_table_id", oci_core_default_route_table.public_route_table.id)
  dns_label                  = replace(replace(each.key, "-", ""), "_", "")
  display_name               = "${each.value.name} subnet"
  security_list_ids          = concat([oci_core_default_security_list.public_subnet_security_list.id], each.value.security_list_ids)
}

resource "oci_core_subnet" "private_subnet" {
  for_each                   = var.private_subnets
  compartment_id             = var.compartment_id
  cidr_block                 = each.value.cidr_block
  prohibit_public_ip_on_vnic = true
  vcn_id                     = oci_core_vcn.vcn.id
  dhcp_options_id            = oci_core_default_dhcp_options.dhcp_options.id
  route_table_id             = lookup(each.value.optionals, "route_table_id", oci_core_route_table.private_route_table.id)
  dns_label                  = replace(replace(each.key, "-", ""), "_", "")
  display_name               = "${each.key} subnet"
  security_list_ids          = concat([oci_core_security_list.private_subnet_security_list.id], each.value.security_list_ids)
}
