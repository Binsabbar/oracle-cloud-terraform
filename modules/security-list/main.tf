locals {
  protocols = {
    icmp = 1
    tcp  = 6
    udp  = 17
  }
}

resource "oci_core_security_list" "security_list" {
  for_each = var.security_lists

  display_name   = each.key
  vcn_id         = var.vcn_id
  compartment_id = var.compartment_id

  # TCP RULES
  dynamic "egress_security_rules" {
    for_each = { for key, rule in each.value.egress_rules : key => rule if rule.protocol == local.protocols.tcp }
    content {
      protocol    = egress_security_rules.value.protocol
      description = egress_security_rules.key
      destination = egress_security_rules.value.destination
      stateless   = false
      tcp_options {
        min = egress_security_rules.value.ports.min
        max = egress_security_rules.value.ports.max
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = { for key, rule in each.value.ingress_rules : key => rule if rule.protocol == local.protocols.tcp }
    content {
      protocol    = ingress_security_rules.value.protocol
      description = ingress_security_rules.key
      source      = ingress_security_rules.value.source
      stateless   = false
      tcp_options {
        min = ingress_security_rules.value.ports.min
        max = ingress_security_rules.value.ports.max
      }
    }
  }

  # UDP RULES
  dynamic "egress_security_rules" {
    for_each = { for key, rule in each.value.egress_rules : key => rule if rule.protocol == local.protocols.udp }
    content {
      protocol    = egress_security_rules.value.protocol
      description = egress_security_rules.key
      destination = egress_security_rules.value.destination
      stateless   = false
      udp_options {
        min = egress_security_rules.value.ports.min
        max = egress_security_rules.value.ports.max
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = { for key, rule in each.value.ingress_rules : key => rule if rule.protocol == local.protocols.udp }
    content {
      protocol    = ingress_security_rules.value.protocol
      description = ingress_security_rules.key
      source      = ingress_security_rules.value.source
      stateless   = false
      udp_options {
        min = ingress_security_rules.value.ports.min
        max = ingress_security_rules.value.ports.max
      }
    }
  }

  # Non UDP or TCP rules
  dynamic "egress_security_rules" {
    for_each = { for key, rule in each.value.egress_rules : key => rule if(rule.protocol != local.protocols.udp && rule.protocol != local.protocols.tcp) }
    content {
      protocol    = egress_security_rules.value.protocol
      description = egress_security_rules.key
      destination = egress_security_rules.value.destination
      stateless   = false
    }
  }

  dynamic "ingress_security_rules" {
    for_each = { for key, rule in each.value.ingress_rules : key => rule if(rule.protocol != local.protocols.udp && rule.protocol != local.protocols.tcp) }
    content {
      protocol    = ingress_security_rules.value.protocol
      description = ingress_security_rules.key
      source      = ingress_security_rules.value.source
      stateless   = false
    }
  }

}
