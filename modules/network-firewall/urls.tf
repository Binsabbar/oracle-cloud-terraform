locals {
  urls_to_fetch = flatten([
    for k, policy in data.oci_network_firewall_network_firewall_policy_url_lists.url_lists : [
      for _, urllist in policy.url_list_summary_collection[0].items :
      {
        name                       = urllist.name
        network_firewall_policy_id = urllist.parent_resource_id
        key                        = "${k}-${urllist.name}"
      }
    ]
  ])

  flattened_url_lists = flatten([
    for k, p in var.policies : p.updatable ? [
      for ku, u in p.url_lists :
      {
        policy_name      = "${k}"
        urls             = [for _, i in u : i if i != ""]
        name             = ku
        key              = "${k}-${ku}"
        updatable_policy = p.updatable
      }
      ] : [
      for _, urllist in local.urls_to_fetch :
      {
        policy_name      = k
        urls             = [for _, u in data.oci_network_firewall_network_firewall_policy_url_list.url_list[urllist.key].urls : u.pattern]
        name             = urllist.name
        key              = urllist.key
        updatable_policy = p.updatable
      } if trimsuffix(urllist.key, "-${urllist.name}") == k
    ]
  ])
}


data "oci_network_firewall_network_firewall_policy_url_lists" "url_lists" {
  for_each = data.oci_network_firewall_network_firewall_policy.network_firewall_policy

  network_firewall_policy_id = each.value.network_firewall_policy_id
}

data "oci_network_firewall_network_firewall_policy_url_list" "url_list" {
  for_each = { for k, v in local.urls_to_fetch : "${v.key}" => v }

  network_firewall_policy_id = each.value.network_firewall_policy_id
  name                       = each.value.name
}

resource "oci_network_firewall_network_firewall_policy_url_list" "url_list" {
  for_each                   = { for _, v in local.flattened_url_lists : "${v.key}" => v }
  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  dynamic "urls" {
    for_each = each.value.urls
    content {
      pattern = urls.value
      type    = "SIMPLE"
    }
  }

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}
