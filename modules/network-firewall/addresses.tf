locals {
  addresses_to_fetch = flatten([
    for k, v in data.oci_network_firewall_network_firewall_policy_address_lists.address_lists : [
      for _, address in v.address_list_summary_collection[0].items : {
        name                       = address.name
        network_firewall_policy_id = address.parent_resource_id
        key                        = "${k}-${address.name}"
      }
    ]
  ])

  flattened_address_lists = flatten([
    for k, p in var.policies : p.updatable ? [
      for ka, a in p.address_lists :
      {
        policy_name      = k
        addresses        = [for _, i in a : i if i != ""]
        name             = ka
        key              = "${k}-${ka}"
        updatable_policy = p.updatable
      }
      ] : [
      for ka, address in data.oci_network_firewall_network_firewall_policy_address_list.address_list :
      {
        policy_name      = k
        addresses        = address.addresses
        name             = address.name
        key              = ka
        updatable_policy = p.updatable
      } if trimsuffix(ka, "-${address.name}") == k
    ]
  ])
}

data "oci_network_firewall_network_firewall_policy_address_list" "address_list" {
  for_each = { for _, v in local.addresses_to_fetch : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = each.value.network_firewall_policy_id
}

data "oci_network_firewall_network_firewall_policy_address_lists" "address_lists" {
  for_each = var.policies

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id
}

resource "oci_network_firewall_network_firewall_policy_address_list" "address_list" {
  for_each                   = { for _, v in local.flattened_address_lists : "${v.key}" => v }
  name                       = each.value.name
  type                       = "IP"
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  addresses                  = each.value.addresses
  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}
