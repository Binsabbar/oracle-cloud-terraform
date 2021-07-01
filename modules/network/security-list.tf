locals {
  protocols = {
    icmp = 1
    tcp  = 6
    udp  = 17
  }

  icmp_types = [0, 3, 4, 8, 11]
}

resource "oci_core_default_security_list" "public_subnet_security_list" {
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
  display_name               = "default public security list"

  dynamic "ingress_security_rules" {
    for_each = var.allowed_ingress_ports
    content {
      protocol    = local.protocols.tcp
      description = "Inbound for port ${ingress_security_rules.value} from all"
      source      = "0.0.0.0/0"
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.default_security_list_rules.public_subnets.enable_icpm_from_all ? local.icmp_types : []
    content {
      protocol    = local.protocols.icmp
      description = "Inbound ICMP type ${ingress_security_rules.value} from all"
      source      = "0.0.0.0/0"
      icmp_options {
        type = ingress_security_rules.value
      }
    }
  }
  
  dynamic "egress_security_rules" {
    for_each = var.default_security_list_rules.public_subnets.enable_icpm_to_all ? local.icmp_types : []
    content {
      protocol    = local.protocols.icmp
      description = "Outbound ICMP type ${egress_security_rules.value} to all"
      destination = "0.0.0.0/0"
      icmp_options {
        type = egress_security_rules.value
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = var.default_security_list_rules.public_subnets.tcp_egress_ports_to_all
    content {
      protocol    = local.protocols.tcp
      description = "Outbound TCP to port ${egress_security_rules.value}"
      destination = "0.0.0.0/0"
      tcp_options {
        max = egress_security_rules.value
        min = egress_security_rules.value
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = var.default_security_list_rules.public_subnets.udp_egress_ports_to_all
    content {
      protocol    = local.protocols.udp
      description = "Outbound UDP to port ${egress_security_rules.value}"
      destination = "0.0.0.0/0"
      udp_options {
        max = egress_security_rules.value
        min = egress_security_rules.value
      }
    }
  }
}

resource "oci_core_security_list" "private_subnet_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "default private security list"

  dynamic "ingress_security_rules" {
    for_each = var.default_security_list_rules.private_subnets.enable_icpm_from_vcn ? local.icmp_types : []
    content {
      protocol    = local.protocols.icmp
      description = "Inbound ICMP type ${ingress_security_rules.value} from VCN ${oci_core_vcn.vcn.display_name}"
      source      = oci_core_vcn.vcn.cidr_block
      icmp_options {
        type = ingress_security_rules.value
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = var.default_security_list_rules.private_subnets.enable_icpm_to_all ? local.icmp_types : []
    content {
      protocol    = local.protocols.icmp
      description = "Inbound ICMP type ${egress_security_rules.value} to all"
      destination = "0.0.0.0/0"
      icmp_options {
        type = egress_security_rules.value
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = var.default_security_list_rules.private_subnets.tcp_egress_ports_to_all
    content {
      protocol    = local.protocols.tcp
      description = "Outbound TCP to port ${egress_security_rules.value}"
      destination = "0.0.0.0/0"
      tcp_options {
        max = egress_security_rules.value
        min = egress_security_rules.value
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = var.default_security_list_rules.private_subnets.udp_egress_ports_to_all
    content {
      protocol    = local.protocols.udp
      description = "Outbound UDP to port ${egress_security_rules.value}"
      destination = "0.0.0.0/0"
      udp_options {
        max = egress_security_rules.value
        min = egress_security_rules.value
      }
    }
  }
}
