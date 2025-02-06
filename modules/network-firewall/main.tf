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

  flattened_rules = flatten([
    for k, p in var.policies : [
      for i, r in p.rules :
      merge(r, {
        policy_name = "${k}"
        key         = "${k}-${r.name}"
        position    = i
        order_rule  = p.order_rules
      })
    ]
  ])

  flattened_address_lists = flatten([
    for k, p in var.policies : [
      for ka, a in p.address_lists :
      {
        policy_name = "${k}"
        addresses   = [for _, i in a : i if i != ""]
        name        = ka
        key         = "${k}-${ka}"
      }
    ]
  ])

  flattened_url_lists = flatten([
    for k, p in var.policies : [
      for ku, u in p.url_lists :
      {
        policy_name = "${k}"
        urls        = [for _, i in u : i if i != ""]
        name        = ku
        key         = "${k}-${ku}"
      }
    ]
  ])

  flattened_service_lists = flatten([
    for k, p in var.policies : [
      for ks, s in try(p.services.lists, []) :
      {
        policy_name = "${k}"
        services    = [for _, i in s : i if i != ""]
        name        = ks
        key         = "${k}-${ks}"
      }
    ]
  ])

  flattened_services = flatten([
    for k, p in var.policies : [
      for ks, s in try(p.services.definitions, []) :
      merge(s, { policy_name = "${k}", key = "${k}-${ks}", name = ks })
    ]
  ])

  flattened_applications = flatten([
    for k, p in var.policies : [
      for ka, a in try(p.applications.definitions, []) :
      merge(a, { policy_name = "${k}", key = "${k}-${ka}", name = ka })
    ]
  ])

  flattened_application_lists = flatten([
    for k, p in var.policies : [
      for ka, a in try(p.applications.lists, []) :
      {
        policy_name  = "${k}"
        applications = [for _, i in a : i if i != ""]
        name         = ka
        key          = "${k}-${ka}"
      }
    ]
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
}

resource "oci_network_firewall_network_firewall_policy" "network_firewall_policy" {
  for_each = var.policies

  display_name   = each.value.name
  compartment_id = each.value.compartment_id
}

resource "oci_network_firewall_network_firewall_policy_security_rule" "security_rule" {
  for_each = { for i, v in local.flattened_rules : "${v.key}" => v }

  action                     = each.value.action
  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id

  inspection = each.value.inspection

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

  lifecycle {
    ignore_changes = [position]
  }
}

// order security rules using external binary
resource "time_sleep" "wait_5s" {
  create_duration = "5s"
  depends_on      = [oci_network_firewall_network_firewall_policy_security_rule.security_rule]
}

resource "null_resource" "write_json_files" {
  for_each = { for k, v in var.policies : k => v if v.order_rules }

  provisioner "local-exec" {
    command = format("echo '%s' > %s", jsonencode({ rules = each.value.rules }), "${path.module}/security-rules-${each.key}.json")
    quiet = true
  }
  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [time_sleep.wait_5s]
}

resource "null_resource" "run_order_security_rules" {
  for_each = { for k, v in var.policies : k => v if v.order_rules }

  provisioner "local-exec" {
    command = "${path.module}/order-security-rules/order-security-rules_${var.go_binary_os_arch} -i ${path.module}/security-rules-${each.key}.json  -p ${oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id} ${var.path_to_oci_config == "" ? "" : format("-c %s",var.path_to_oci_config)}"
  }
  
  provisioner "local-exec" {
    command = "rm -fr ${path.module}/security-rules-${each.key}.json"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [ null_resource.write_json_files ]
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
