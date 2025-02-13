locals {

  security_rules_to_fetch = flatten([
    for k, policy in data.oci_network_firewall_network_firewall_policy_security_rules.security_rules : [
      for _, security_rule in policy.security_rule_summary_collection[0].items :
      {
        name                       = security_rule.name
        network_firewall_policy_id = security_rule.parent_resource_id
        key                        = "${k}-${security_rule.name}"
      }
    ]
  ])

  flattened_rules = flatten([
    for k, p in var.policies : p.updatable ? [
      for i, r in p.rules :
      {
        name             = r.name
        policy_name      = "${k}"
        key              = "${k}-${r.name}"
        position         = i
        action           = r.action
        inspection       = r.inspection
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
      }
      ] : [
      for i, rule in data.oci_network_firewall_network_firewall_policy_security_rule.security_rule :
      {
        name                         = rule.name
        policy_name                  = "${k}"
        key                          = "${k}-${rule.name}"
        position                     = i
        action                       = rule.action
        inspection                   = rule.inspection
        order_rule                   = p.order_rules
        updatable_policy             = p.updatable
        computed_destination_address = rule.condition[0].destination_address
        computed_source_address      = rule.condition[0].source_address
        computed_service             = rule.condition[0].service
        computed_url                 = rule.condition[0].url
        computed_application         = rule.condition[0].application
      } if trimsuffix(i, "-${rule.name}") == k
    ]
  ])
}

data "oci_network_firewall_network_firewall_policy_security_rules" "security_rules" {
  for_each = data.oci_network_firewall_network_firewall_policy.network_firewall_policy

  network_firewall_policy_id = each.value.network_firewall_policy_id
}

data "oci_network_firewall_network_firewall_policy_security_rule" "security_rule" {
  for_each = { for k, v in local.security_rules_to_fetch : "${v.key}" => v }

  network_firewall_policy_id = each.value.network_firewall_policy_id
  name                       = each.value.name
}

resource "oci_network_firewall_network_firewall_policy_security_rule" "security_rule" {
  for_each = { for i, v in local.flattened_rules : "${v.key}" => v }

  action                     = each.value.action
  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id

  inspection = each.value.inspection

  condition {
    destination_address = each.value.computed_destination_address
    source_address      = each.value.computed_source_address
    service             = each.value.computed_service
    url                 = each.value.computed_url
    application         = each.value.computed_application
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
  for_each = { for k, v in var.policies : k => v if v.order_rules && v.updatable }

  provisioner "local-exec" {
    command = format("echo '%s' > %s", jsonencode({ rules = each.value.rules }), "${path.module}/security-rules-${each.key}.json")
    quiet   = true
  }
  triggers = {
    ordered_updatable = "order=[${join(",", [for _, item in each.value.rules : item.name])}]"
    force_order       = "${each.value.force_order ? timestamp() : 0}"
  }

  depends_on = [time_sleep.wait_5s]
}

resource "null_resource" "run_order_security_rules" {
  for_each = { for k, v in var.policies : k => v if v.order_rules && v.updatable }

  provisioner "local-exec" {
    command = "${path.module}/order-security-rules/order-security-rules_${var.go_binary_os_arch} -i ${path.module}/security-rules-${each.key}.json  -p ${oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id} ${var.path_to_oci_config == "" ? "" : format("-o %s", var.path_to_oci_config)}"
  }

  provisioner "local-exec" {
    command = "rm -fr ${path.module}/security-rules-${each.key}.json"
  }

  depends_on = [null_resource.write_json_files]

  triggers = {
    id = null_resource.write_json_files[each.key].id
  }

  lifecycle {
    precondition {
      condition     = !contains(local.active_policies, each.value.name)
      error_message = "You can't make changes to active policy. ${each.value.name} is attached to a firewall"
    }
  }
}
