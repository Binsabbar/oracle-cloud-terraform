// 
locals {
  public_route_table_key  = "igw=${var.internet_gateway.enable}:svcgw=${var.service_gateway.enable}"
  private_route_table_key = "natgw=${var.nat_gateway.enable}:svcgw=${var.service_gateway.enable}"

  private_route_table = {
    "${local.private_route_table_key}" = {}
  }

  public_route_table = {
    "${local.public_route_table_key}" = {}
  }

  flattened_local_peering_gateways_cidrs = flatten([for k, v in var.local_peering_gateway : [
    for cidr in v.destination_cidrs : {
      name = k
      cidr = cidr
    }]
  ])
}

resource "oci_core_vcn" "vcn" {
  cidr_block                       = var.cidr_block
  compartment_id                   = var.compartment_id
  display_name                     = var.name
  dns_label                        = var.name
  is_ipv6enabled                   = var.ipv6.enabled
  is_oracle_gua_allocation_enabled = var.ipv6.oci_allocation
  ipv6private_cidr_blocks          = var.ipv6.cidr_block
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
  count = var.internet_gateway.enable ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = var.internet_gateway.enable
  display_name   = "defaultInternetGateway"

  route_table_id = lookup(var.internet_gateway.optionals, "route_table_id", "")
}

resource "oci_core_nat_gateway" "nat_gateway" {
  count = var.nat_gateway.enable ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "defaultNatGateway"
  public_ip_id   = var.nat_gateway.public_ip_id
  block_traffic  = var.nat_gateway.block_traffic

  route_table_id = lookup(var.nat_gateway.optionals, "route_table_id", "")
}

resource "oci_core_service_gateway" "service_gateway" {
  count = var.service_gateway.enable ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "defaultServiceGateway"
  services {
    service_id = var.service_gateway.service_id
  }
  route_table_id = lookup(var.service_gateway.optionals, "route_table_id", "")
}

resource "oci_core_local_peering_gateway" "peering_gateway" {
  for_each       = var.local_peering_gateway
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name   = each.value.name
  peer_id        = each.value.peer_id
  route_table_id = each.value.route_table_id
}

// Routes
resource "oci_core_default_route_table" "public_route_table" {
  for_each                   = local.public_route_table
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id
  display_name               = "defaultRouteTable"
  dynamic "route_rules" {
    for_each = var.internet_gateway.enable == true ? toset([0]) : []
    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_internet_gateway.internet_gateway[0].id
    }
  }

  dynamic "route_rules" {
    for_each = { for item in local.flattened_local_peering_gateways_cidrs : "${item.name}:${item.cidr}" => item }
    content {
      description       = route_rules.key
      destination       = route_rules.value.cidr
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_local_peering_gateway.peering_gateway[route_rules.value.name].id
    }
  }
  dynamic "route_rules" {
    for_each = var.service_gateway.enable == true && var.service_gateway.add_route_rule_in_public_subnet == true ? toset([0]) : []
    content {
      destination       = var.service_gateway.route_rule_destination
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.service_gateway[0].id
    }
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
  for_each = local.private_route_table

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "defaultPrivateRouteTable"

  dynamic "route_rules" {
    for_each = var.nat_gateway.enable == true ? toset([0]) : []
    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.nat_gateway[0].id
    }
  }

  dynamic "route_rules" {
    for_each = var.service_gateway.enable == true ? toset([0]) : []
    content {
      destination       = var.service_gateway.route_rule_destination
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.service_gateway[0].id
    }
  }

  dynamic "route_rules" {
    for_each = { for item in local.flattened_local_peering_gateways_cidrs : "${item.name}:${item.cidr}" => item }
    content {
      description       = route_rules.key
      destination       = route_rules.value.cidr
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_local_peering_gateway.peering_gateway[route_rules.value.name].id
    }
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
  dns_label                  = replace(replace(each.key, "-", ""), "_", "")
  display_name               = "${each.value.name} subnet"
  security_list_ids          = concat([oci_core_default_security_list.public_subnet_security_list.id], each.value.security_list_ids)
  ipv6cidr_block             = each.value.ipv6cidr_block
}

resource "oci_core_subnet" "private_subnet" {
  for_each                   = var.private_subnets
  compartment_id             = var.compartment_id
  cidr_block                 = each.value.cidr_block
  prohibit_public_ip_on_vnic = true
  vcn_id                     = oci_core_vcn.vcn.id
  dhcp_options_id            = oci_core_default_dhcp_options.dhcp_options.id
  dns_label                  = replace(replace(each.key, "-", ""), "_", "")
  display_name               = "${each.key} subnet"
  security_list_ids          = concat([oci_core_security_list.private_subnet_security_list.id], each.value.security_list_ids)
  ipv6cidr_block             = each.value.ipv6cidr_block
}

// Route Table Association
resource "oci_core_route_table_attachment" "public_route_table_attachment" {
  for_each       = var.public_subnets
  subnet_id      = oci_core_subnet.public_subnet[each.key].id
  route_table_id = lookup(each.value.optionals, "route_table_id", oci_core_default_route_table.public_route_table[local.public_route_table_key].id)
}

resource "oci_core_route_table_attachment" "private_route_table_attachment" {
  for_each       = var.private_subnets
  subnet_id      = oci_core_subnet.private_subnet[each.key].id
  route_table_id = lookup(each.value.optionals, "route_table_id", oci_core_route_table.private_route_table[local.private_route_table_key].id)
}

// DNS Resolver
data "oci_core_vcn_dns_resolver_association" "vcn_dns_resolver_association" {
  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_dns_resolver" "dns_resolver" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.vcn_dns_resolver_association.dns_resolver_id

  dynamic "attached_views" {
    for_each = var.dns_private_views
    content {
      view_id = attached_views.value.view_id
    }
  }
}
