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
  updatable_policies = { for k, v in var.policies : k => v if !v.updatable }

  policies_to_get = flatten([
    for k, policy in data.oci_network_firewall_network_firewall_policies.network_firewall_policies : [
      for _, policy_info in policy.network_firewall_policy_summary_collection[0].items :
      {
        name = policy_info.display_name
        id   = policy_info.id
        key  = k
      } if try(policy_info.freeform_tags["terraform_resource_name"], null) == k
    ]
    ]
  )
}


data "oci_network_firewall_network_firewall_policies" "network_firewall_policies" {
  for_each       = local.updatable_policies
  compartment_id = each.value.compartment_id
}


data "oci_network_firewall_network_firewall_policy" "network_firewall_policy" {
  for_each                   = { for _, v in local.policies_to_get : v.key => v }
  network_firewall_policy_id = each.value.id
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

  depends_on = [null_resource.run_order_security_rules]
}

resource "oci_network_firewall_network_firewall_policy" "network_firewall_policy" {
  for_each = var.policies

  display_name   = each.value.name
  compartment_id = each.value.compartment_id

  freeform_tags = {
    terraform_resource_name = each.key
  }
}
