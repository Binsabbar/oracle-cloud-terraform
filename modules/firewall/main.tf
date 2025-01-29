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
      for _, r in v.rules :
      merge(r, {
        policy_name = "${k}"
        key         = "${k}-${r.name}"
      })
    ]
  ])
  flattened_address_lists = flatten([
    for k, v in var.policies : [
      for kr, a in v.address_list :
      {
        policy_name = "${k}"
        addresses   = a
        list_name   = kr
        key         = "${k}-${kr}"
      }
    ]
  ])

}

resource "oci_network_firewall_network_firewall_policy_security_rule" "security_rule" {
  for_each = { for i, v in local.flattened_rules : "${v.key}" => merge({ position = i }, v) }

  action                     = each.value.action
  name                       = each.value.name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id

  condition {
    destination_address = [for _, v in each.value.destination_addresses :
      oci_network_firewall_network_firewall_policy_address_list.address_list["${each.value.policy_name}-${v}"].name
    ]
    source_address = [for _, v in each.value.source_addresses :
      oci_network_firewall_network_firewall_policy_address_list.address_list["${each.value.policy_name}-${v}"].name
    ]
    # application         = var.network_firewall_policy_security_rule_condition_application
    # service             = var.network_firewall_policy_security_rule_condition_service
    # url                 = var.network_firewall_policy_security_rule_condition_url
  }

  position {
    after_rule = each.value.position == 0 ? null : local.policies[each.value.policy_name].rules[each.value.position - 1].name
  }
}

resource "oci_network_firewall_network_firewall_policy_address_list" "address_list" {
  for_each                   = { for _, v in local.flattened_address_lists : "${v.key}" => v }
  name                       = each.value.list_name
  type                       = "IP"
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.value.policy_name].id
  addresses                  = each.value.addresses
}

# Application
resource "oci_network_firewall_network_firewall_policy_application" "application" {
  #Required
  icmp_type                  = var.network_firewall_policy_application_icmp_type
  name                       = var.network_firewall_policy_application_name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy.id
  type                       = var.network_firewall_policy_application_type

  #Optional
  icmp_code = var.network_firewall_policy_application_icmp_code
}


resource "oci_network_firewall_network_firewall_policy_application_group" "application_group" {
  #Required
  apps                       = var.network_firewall_policy_application_group_apps
  name                       = var.network_firewall_policy_application_group_name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy.id
}



# Services
resource "oci_network_firewall_network_firewall_policy_service" "service" {
  #Required
  name                       = var.network_firewall_policy_service_name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy.id
  port_ranges {
    #Required
    minimum_port = var.network_firewall_policy_service_port_ranges_minimum_port

    #Optional
    maximum_port = var.network_firewall_policy_service_port_ranges_maximum_port
  }
  type = var.network_firewall_policy_service_type
}

resource "oci_network_firewall_network_firewall_policy_service_list" "service_list" {
  #Required
  name                       = var.network_firewall_policy_service_list_name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy.id
  services                   = var.network_firewall_policy_service_list_services
}


# URL
resource "oci_network_firewall_network_firewall_policy_url_list" "url_list" {
  #Required
  name                       = var.network_firewall_policy_url_list_name
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy.id
  urls {
    #Required
    pattern = var.network_firewall_policy_url_list_urls_pattern
    type    = var.network_firewall_policy_url_list_urls_type
  }
}
