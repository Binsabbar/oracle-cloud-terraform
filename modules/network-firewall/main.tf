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
    for _, v in var.firewalls: v.policy_name
  ])
  flattened_rules = flatten([
    for k, p in var.policies : [
      for i, r in p.rules :
      merge(r, {
        policy_name      = "${k}"
        key              = "${k}-${r.name}"
        position         = i
        order_rule       = p.order_rules
        updatable_policy = p.updatable
        computed_destination_address = [for _, v in try(r.destination_addresses, []) :
          oci_network_firewall_network_firewall_policy_address_list.address_list["${k}-${v}"].name
        ]
        computed_source_address = [for _, v in try(r.source_addresses, []) :
          oci_network_firewall_network_firewall_policy_address_list.address_list["${k}-${v}"].name
        ]
        computed_service = [for _, v in try(r.service_lists, []) :
          oci_network_firewall_network_firewall_policy_service_list.service_list["${k}-${v}"].name
        ]
        computed_url = [for _, v in try(r.url_lists, []) :
          oci_network_firewall_network_firewall_policy_url_list.url_list["${k}-${v}"].name
        ]
        computed_application = [for _, v in try(r.application_lists, []) :
          oci_network_firewall_network_firewall_policy_application_group.application_group["${k}-${v}"].name
        ]
      })
    ]
  ])

  flattened_address_lists = flatten([
    for k, p in var.policies : p.updatable ? [
      for ka, a in p.address_lists :
      {
        policy_name      = "${k}"
        addresses        = [for _, i in a : i if i != ""]
        name             = ka
        key              = "${k}-${ka}"
        updatable_policy = p.updatable
      }
    ]:[
      for ka, a in data.oci_network_firewall_network_firewall_policy_address_lists.address_lists[k].address_list_summary_collection[0].items :
      {
        policy_name      = "${k}"
        addresses        = a.addresses
        name             = a.name
        key              = "${k}-${a.name}"
        updatable_policy = p.updatable
      }
    ]
  ])

  flattened_url_lists = flatten([
    for k, p in var.policies : [
      for ku, u in p.url_lists :
      {
        policy_name      = "${k}"
        urls             = [for _, i in u : i if i != ""]
        name             = ku
        key              = "${k}-${ku}"
        updatable_policy = p.updatable
      }
    ]
  ])

  flattened_service_lists = flatten([
    for k, p in var.policies : [
      for ks, s in try(p.services.lists, []) :
      {
        policy_name      = "${k}"
        services         = [for _, i in s : i if i != ""]
        name             = ks
        key              = "${k}-${ks}"
        updatable_policy = p.updatable
        computed_services = [for _, item in s :
          oci_network_firewall_network_firewall_policy_service.service["${k}-${item}"].name
        ]
      }
    ]
  ])

  flattened_services = flatten([
    for k, p in var.policies : [
      for ks, s in try(p.services.definitions, []) :
      merge(s, { policy_name = "${k}", key = "${k}-${ks}", name = ks, updatable_policy = p.updatable })
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

data "oci_network_firewall_network_firewall_policy_security_rule" "security_rule" {
  for_each = { for i, v in local.flattened_rules : "${v.key}" => v }

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  name         = each.value.name
}

resource "oci_network_firewall_network_firewall_policy_security_rule" "security_rule" {
  for_each = { for i, v in local.flattened_rules : "${v.key}" => v }

  action                     = each.value.updatable_policy ? each.value.action : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].action, each.value.action)
  name                       = each.value.updatable_policy ? each.value.name : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].name, each.value.name)
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id

  inspection = each.value.updatable_policy ? each.value.inspection : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].inspection, each.value.inspection)

  condition {
    destination_address = each.value.updatable_policy ? each.value.computed_destination_address : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].condition[0].destination_address, each.value.computed_destination_address)
    source_address      = each.value.updatable_policy ? each.value.computed_source_address : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].condition[0].source_address, each.value.computed_source_address)
    service             = each.value.updatable_policy ? each.value.computed_service : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].condition[0].service, each.value.computed_service)
    url                 = each.value.updatable_policy ? each.value.computed_url : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].condition[0].url, each.value.computed_url)
    application         = each.value.updatable_policy ? each.value.computed_application : try(data.oci_network_firewall_network_firewall_policy_security_rule.security_rule[each.key].condition[0].application, each.value.computed_application)
  }

  lifecycle {
    ignore_changes = [position]
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
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
    quiet   = true
  }
  triggers = {
    ordered_updatable = "ordere:${each.value.order_rules},updatable:${each.value.updatable}"
  }

  depends_on = [time_sleep.wait_5s]
}

resource "null_resource" "run_order_security_rules" {
  for_each = { for k, v in var.policies : k => v if v.order_rules }

  provisioner "local-exec" {
    command = "${path.module}/order-security-rules/order-security-rules_${var.go_binary_os_arch} -i ${path.module}/security-rules-${each.key}.json  -p ${oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id} ${var.path_to_oci_config == "" ? "" : format("-o %s", var.path_to_oci_config)}"
  }

  provisioner "local-exec" {
    command = "rm -fr ${path.module}/security-rules-${each.key}.json"
  }

  depends_on = [null_resource.write_json_files]
  
  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.name)
      error_message = "You can't make changes to active policy. ${each.value.name} is attached to a firewall"
    }
  }
}

# Address List
data "oci_network_firewall_network_firewall_policy_address_lists" "address_lists" {
  for_each = var.policies 

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id
}

data "oci_network_firewall_network_firewall_policy_address_list" "address_list" {
  for_each = { for _, v in local.flattened_address_lists : "${v.key}" => v }

  name = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
}

resource "oci_network_firewall_network_firewall_policy_address_list" "address_list" {
  for_each                   = { for _, v in local.flattened_address_lists : "${v.key}" => v }
  name                       = each.value.updatable_policy ? each.value.name : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_address_list.address_list, each.key, {name=null}).name, each.value.name)
  type                       = "IP"
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  addresses                  = each.value.updatable_policy ? each.value.addresses : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_address_list.address_list, each.key, {addresses=null}).addresses, each.value.addresses)
  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}

# Service and Service List
data "oci_network_firewall_network_firewall_policy_service" "service" {
  for_each                   = { for _, v in local.flattened_services : "${v.key}" => v }
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  name               = each.value.name
}

resource "oci_network_firewall_network_firewall_policy_service" "service" {
  for_each = { for _, v in local.flattened_services : "${v.key}" => v }

  name                       = each.value.updatable_policy ? each.value.name : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_service.service, each.key, {name=null}).name, each.value.name)
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  dynamic "port_ranges" {
    for_each = each.value.updatable_policy ? each.value.port_ranges : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_service.service, each.key).port_ranges, each.value.port_ranges)
    content {
      minimum_port = port_ranges.value.minimum_port
      maximum_port = port_ranges.value.maximum_port
    }
  }
  type = each.value.updatable_policy ? local.service_type_map[upper(each.value.type)] : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_service.service, each.key, {type=null}).type, local.service_type_map[upper(each.value.type)])

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}

data "oci_network_firewall_network_firewall_policy_service_list" "service_list" {
  for_each = { for _, v in local.flattened_service_lists : "${v.key}" => v }

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  name          = each.value.name
}
resource "oci_network_firewall_network_firewall_policy_service_list" "service_list" {
  for_each = { for _, v in local.flattened_service_lists : "${v.key}" => v }

  name                       = each.value.updatable_policy ? each.value.name : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_service_list.service_list, each.key, {name=null}).name, each.value.name)
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  services = each.value.updatable_policy ? each.value.computed_services : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_service_list.service_list, each.key, {services=null}).services, each.value.computed_services)

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}

# Application and Application List
resource "oci_network_firewall_network_firewall_policy_application" "application" {
  for_each = { for _, v in local.flattened_applications : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  type                       = local.icmp_type_map[upper(each.value.protocol)]
  icmp_type                  = each.value.type
  icmp_code                  = try(each.value.icmp_code, null)

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}

resource "oci_network_firewall_network_firewall_policy_application_group" "application_group" {
  for_each = { for _, v in local.flattened_application_lists : "${v.key}" => v }

  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  apps = [for _, item in each.value.applications :
    oci_network_firewall_network_firewall_policy_application.application["${each.value.policy_name}-${item}"].name
  ]
  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.policy_name)
      error_message = "You can't make changes to active policy. ${each.value.policy_name} is attached to a firewall"
    }
  }
}

# URL List
data "oci_network_firewall_network_firewall_policy_url_list" "url_lists" {
  for_each = var.policies 

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id
}

data "oci_network_firewall_network_firewall_policy_url_list" "url_list" {
  for_each = { for _, v in local.flattened_url_lists : "${v.key}" => v }

  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  name              = each.value.name
}

resource "oci_network_firewall_network_firewall_policy_url_list" "url_list" {
  for_each                   = { for _, v in local.flattened_url_lists : "${v.key}" => v }
  # name                       = each.value.updatable_policy ? each.value.name : try(lookup(data.oci_network_firewall_network_firewall_policy_url_list.url_list, each.key).name, each.value.name)
  name                       = each.value.updatable_policy ? each.value.name : coalesce(lookup(data.oci_network_firewall_network_firewall_policy_url_list.url_list, each.key, {}).name, each.value.name)
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  dynamic "urls" {
    for_each = each.value.updatable_policy ? each.value.urls : try(lookup(data.oci_network_firewall_network_firewall_policy_url_list.url_list, each.key, null).urls[*].pattern, each.value.urls)
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
