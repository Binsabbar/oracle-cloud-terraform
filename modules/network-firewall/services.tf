locals {

  service_lists_to_fetch = flatten([
    for k, p in data.oci_network_firewall_network_firewall_policy_service_lists.all_service_lists : [
      for _, servicelist in p.service_list_summary_collection[0].items : {
        name                       = servicelist.name
        network_firewall_policy_id = servicelist.parent_resource_id
        key                        = "${k}-${servicelist.name}"
      }
    ]
  ])

  flattened_service_lists = flatten([
    for k, p in var.policies : p.updatable ? [
      for ks, s in try(p.services.lists, []) :
      {
        policy_name      = "${k}"
        name             = ks
        key              = "${k}-${ks}"
        updatable_policy = p.updatable
        services         = [for _, i in s : i if i != ""]
        computed_services = [for _, item in s :
          oci_network_firewall_network_firewall_policy_service.service["${k}-${item}"].name
        ]
      }
      ] : [
      for ks, servicelist in data.oci_network_firewall_network_firewall_policy_service_list.service_list :
      {
        policy_name       = "${k}"
        name              = servicelist.name
        key               = "${k}-${servicelist.name}"
        updatable_policy  = p.updatable
        services          = servicelist.services
        computed_services = servicelist.services
      } if trimsuffix(ks, "-${servicelist.name}") == k
    ]
  ])

  services_to_fetch = flatten([
    for k, servicelist in data.oci_network_firewall_network_firewall_policy_service_list.service_list : [
      for _, service in servicelist.services :
      {
        name                       = service
        network_firewall_policy_id = servicelist.parent_resource_id
        # policy-name = trimsuffix(ks, "-${servicelist.name}") so the key will be policyname-servicename
        key = format("%s-%s", trimsuffix(k, "-${servicelist.name}"), service)
      }
    ]
  ])

  flattened_services = flatten([
    for k, p in var.policies : p.updatable ? [
      for ks, service in try(p.services.definitions, []) :
      merge(service, { policy_name = "${k}", key = "${k}-${ks}", name = ks, updatable_policy = p.updatable })
      ] : [
      for ks, service in data.oci_network_firewall_network_firewall_policy_service.service :
      {
        policy_name      = "${k}"
        key              = "${k}-${service.name}"
        name             = service.name
        updatable_policy = p.updatable
        port_ranges      = service.port_ranges
        type             = service.type
      } if trimsuffix(ks, "-${service.name}") == k
    ]
  ])
}

data "oci_network_firewall_network_firewall_policy_service_lists" "all_service_lists" {
  for_each                   = var.policies
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id
}

data "oci_network_firewall_network_firewall_policy_service_list" "service_list" {
  for_each                   = { for k, v in local.service_lists_to_fetch : "${v.key}" => v }
  network_firewall_policy_id = each.value.network_firewall_policy_id
  name                       = each.value.name
}

data "oci_network_firewall_network_firewall_policy_service" "service" {
  for_each = { for k, v in local.services_to_fetch : "${v.key}" => v }

  network_firewall_policy_id = each.value.network_firewall_policy_id
  name                       = each.value.name
}

resource "oci_network_firewall_network_firewall_policy_service" "service" {
  for_each = { for _, v in local.flattened_services : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  dynamic "port_ranges" {
    for_each = each.value.port_ranges
    content {
      minimum_port = port_ranges.value.minimum_port
      maximum_port = port_ranges.value.maximum_port
    }
  }
  type = local.service_type_map[upper(each.value.type)]

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}

resource "oci_network_firewall_network_firewall_policy_service_list" "service_list" {
  for_each = { for _, v in local.flattened_service_lists : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  services                   = each.value.computed_services

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}
