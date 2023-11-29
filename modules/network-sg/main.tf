locals {
  protocols = {
    icmp = 1
    tcp  = 6
    udp  = 17
    all  = "all"
  }
}

locals {
  // map the network_security_groups into an array of all rules flattened
  /*
  from:
    {"group-1" = {"rule-1" = { ips = [1, 2], port=22, ...}}, ....}
  To:
    [{group = "group-1", rulename= "rule-1", port = 22, ip = 1}, {group = "group-1", rulename= "rule-1", port = 22, ip = 2} ]
  */
  flatten_rules = flatten([
    for group, rules in var.network_security_groups : [
      for rulename, rule in rules : [
        for ip in rule.ips : {
          group     = group
          rulename  = rulename
          direction = rule.direction
          protocol  = rule.protocol
          port      = rule.port
          ip        = ip
        }
      ]
    ]
  ])
}

// Create a group
resource "oci_core_network_security_group" "security_group" {
  for_each = var.network_security_groups

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "Security group for ${each.key}"
}

// Create INGRESS rules
resource "oci_core_network_security_group_security_rule" "ingress_rule" {
  for_each = { for rule in local.flatten_rules :
    "${rule.group}:${rule.rulename}:${rule.direction}:${rule.ip}:${rule.port}" => rule
  if rule.direction == "INGRESS" }

  network_security_group_id = oci_core_network_security_group.security_group[each.value.group].id
  direction                 = "INGRESS"
  protocol                  = lookup(local.protocols, each.value.protocol)
  description               = each.value.rulename
  stateless                 = false
  source                    = var.use_nsg_as_source ? each.value.nsg_id : each.value.ip
  source_type               = var.use_nsg_as_source ? "NETWORK_SECURITY_GROUP": "CIDR_BLOCK"

  dynamic "tcp_options" {
    for_each = each.value.protocol == "tcp" ? [each.value.port] : []
    content {
      destination_port_range {
        max = tcp_options.value
        min = tcp_options.value
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "udp" ? [each.value.port] : []
    content {
      destination_port_range {
        max = udp_options.value
        min = udp_options.value
      }
    }
  }
}

// Create EGRESS rules
resource "oci_core_network_security_group_security_rule" "egress_rule" {
  for_each = { for rule in local.flatten_rules :
    "${rule.group}:${rule.rulename}:${rule.direction}:${rule.ip}:${rule.port}" => rule
  if rule.direction == "EGRESS" }

  network_security_group_id = oci_core_network_security_group.security_group[each.value.group].id
  direction                 = "EGRESS"
  protocol                  = lookup(local.protocols, each.value.protocol)
  description               = each.value.rulename
  stateless                 = false
  destination               = each.value.ip
  destination_type          = "CIDR_BLOCK"

  dynamic "tcp_options" {
    for_each = each.value.protocol == "tcp" ? [each.value.port] : []
    content {
      destination_port_range {
        max = tcp_options.value
        min = tcp_options.value
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "udp" ? [each.value.port] : []
    content {
      destination_port_range {
        max = udp_options.value
        min = udp_options.value
      }
    }
  }
}
