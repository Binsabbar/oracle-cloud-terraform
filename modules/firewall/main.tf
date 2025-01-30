locals {
  allowed_actions = ["ALLOW", "DROP", "REJECT", "INSPECT"]
}

resource "oci_network_firewall_network_firewall" "network_firewall" {
  compartment_id      = var.compartment_id
  display_name        = var.name
  availability_domain = var.availability_domain

  subnet_id                  = var.networking.subnet_id
  ipv4address                = var.networking.ipv4address
  ipv6address                = var.networking.ipv6address
  network_security_group_ids = var.networking.security_group_ids

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[var.active_firewall_policy]
}

resource "oci_network_firewall_network_firewall_policy" "network_firewall_policy" {
  for_each = var.policies

  compartment_id = var.compartment_id
  display_name   = var.name
}


locals {
  flattened_rules = flatten([
    for k, v in var.policies : [
      for i, r in v.rules :
      merge(r, {
        policy_name = "${k}"
        key         = "${i}-${k}-${r.name}"
        position    = i
      })
    ]
  ])

  flattened_address_lists = flatten([
    for k, v in var.policies : [
      for kr, a in v.address_lists :
      {
        policy_name = "${k}"
        addresses   = [for _, i in a : i if i != ""]
        name        = kr
        key         = "${k}-${kr}"
      }
    ]
  ])

  flattened_url_lists = flatten([
    for k, v in var.policies : [
      for kr, u in v.url_lists :
      {
        policy_name = "${k}"
        urls        = [for _, i in u : i if i != ""]
        name        = kr
        key         = "${k}-${kr}"
      }
    ]
  ])

  flattened_service_lists = flatten([
    for k, v in var.policies : [
      for ks, s in v.services.lists :
      {
        policy_name = "${k}"
        services    = [for _, i in s : i if i != ""]
        name        = ks
        key         = "${k}-${ks}"
      }
    ]
  ])

  flattened_services = flatten([
    for k, v in var.policies : [
      for ks, s in v.services.definitions :
      merge(s, { policy_name = "${k}", key = "${k}-${ks}", name = ks })
    ]
  ])

  flattened_applications = flatten([
    for k, v in var.policies : [
      for ks, s in v.applications.definitions :
      merge(s, { policy_name = "${k}", key = "${k}-${ks}", name = ks })
    ]
  ])

  flattened_application_lists = flatten([
    for k, v in var.policies : [
      for ks, s in v.applications.lists :
      {
        policy_name  = "${k}"
        applications = [for _, i in s : i if i != ""]
        name         = ks
        key          = "${k}-${ks}"
      }
    ]
  ])

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

}


resource "oci_network_firewall_network_firewall_policy" "network_firewall_policy" {
  for_each = var.policies

  compartment_id = data.oci_identity_compartments.get_compartments["devops"].compartments[0].id
  display_name   = each.value.name
}

resource "oci_network_firewall_network_firewall_policy_security_rule" "security_rule" {
  for_each = { for i, v in local.flattened_rules : "${v.key}" => v }

  action                     = each.value.action
  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id

  condition {
    destination_address = [for _, v in try(each.value.destination_addresses, []) :
      oci_network_firewall_network_firewall_policy_address_list.address_list["${each.value.policy_name}-${v}"].name
    ]
    source_address = [for _, v in try(each.value.source_addresses, []) :
      oci_network_firewall_network_firewall_policy_address_list.address_list["${each.value.policy_name}-${v}"].name
    ]
    service = [for _, v in try(each.value.service_lists, []) :
      oci_network_firewall_network_firewall_policy_service_list.service_list["${each.value.policy_name}-${v}"].name
    ]
    url = [for _, v in try(each.value.url_lists, []) :
      oci_network_firewall_network_firewall_policy_url_list.url_list["${each.value.policy_name}-${v}"].name
    ]
    application = [for _, v in try(each.value.application_lists, []) :
      oci_network_firewall_network_firewall_policy_application_group.application_group["${each.value.policy_name}-${v}"].name
    ]
  }

  position {
    after_rule = each.value.position == 0 ? null : var.policies[each.value.policy_name].rules[each.value.position - 1].name
  }
}


# Address List
resource "oci_network_firewall_network_firewall_policy_address_list" "address_list" {
  for_each                   = { for _, v in local.flattened_address_lists : "${v.key}" => v }
  name                       = each.value.name
  type                       = "IP"
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  addresses                  = each.value.addresses
}

# Service and Service List
resource "oci_network_firewall_network_firewall_policy_service" "service" {
  for_each = { for _, v in local.flattened_services : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  dynamic "port_ranges" {
    for_each = each.value.port_ranges
    content {
      minimum_port = port_ranges.value.min_port
      maximum_port = port_ranges.value.max_port
    }
  }
  type = local.service_type_map[upper(each.value.type)]
}

resource "oci_network_firewall_network_firewall_policy_service_list" "service_list" {
  for_each = { for _, v in local.flattened_service_lists : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  services = [for _, item in each.value.services :
    oci_network_firewall_network_firewall_policy_service.service["${each.value.policy_name}-${item}"].name
  ]
}

# Application and Application List
resource "oci_network_firewall_network_firewall_policy_application" "application" {
  for_each = { for _, v in local.flattened_applications : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  type                       = local.icmp_type_map[upper(each.value.protocol)]
  icmp_type                  = each.value.type
  icmp_code                  = try(each.value.icmp_code, null)
}

resource "oci_network_firewall_network_firewall_policy_application_group" "application_group" {
  for_each = { for _, v in local.flattened_application_lists : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  apps = [for _, item in each.value.applications :
    oci_network_firewall_network_firewall_policy_application.application["${each.value.policy_name}-${item}"].name
  ]

}

# URL List
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
}
