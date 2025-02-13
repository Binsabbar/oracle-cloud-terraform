locals {
  service_type_map = {
    "TCP"         = "TCP_SERVICE"
    "TCP_SERVICE" = "TCP_SERVICE"
    "UDP"         = "UDP_SERVICE"
    "UDP_SERVICE" = "UDP_SERVICE"
  }

  icmp_type_map = {
    "ICMP"    = "ICMP"
    "ICMP_V6" = "ICMP_V6"
  }

  active_policies = flatten([
    for _, v in var.firewalls : v.policy_name
  ])

}

resource "oci_network_firewall_network_firewall" "network_firewall" {
  for_each = var.firewalls

  compartment_id      = each.value.compartment_id
  display_name        = each.value.name
  availability_domain = each.value.availability_domain

  subnet_id                  = each.value.networking.subnet_id
  ipv4address                = each.value.networking.ipv4address
  ipv6address                = each.value.networking.ipv6address
  network_security_group_ids = each.value.networking.security_group_ids

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  depends_on                 = [null_resource.run_order_security_rules]
}

resource "oci_network_firewall_network_firewall_policy" "network_firewall_policy" {
  for_each = var.policies

  display_name   = each.value.name
  compartment_id = each.value.compartment_id

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.name)
      error_message = "You can't make changes to active policy. ${each.value.name} is attached to a firewall"
    }
  }
}