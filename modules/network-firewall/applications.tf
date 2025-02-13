locals {
  application_groups_to_fetch = flatten([
    for k, p in data.oci_network_firewall_network_firewall_policy_application_groups.all_application_groups : [
      for _, application_group in p.application_group_summary_collection[0].items : {
        name                       = application_group.name
        network_firewall_policy_id = application_group.parent_resource_id
        key                        = "${k}-${application_group.name}"
      }
    ]
  ])


  flattened_application_groups = flatten([
    for k, p in var.policies : p.updatable ? [
      for ka, application_group in try(p.applications.lists, []) :
      {
        policy_name  = k
        applications = [for _, i in application_group : i if i != ""]
        name         = ka
        key          = "${k}-${ka}"
        updatable_policy = p.updatable
      }
      ] : [
      for ks, application_group in data.oci_network_firewall_network_firewall_policy_application_group.application_group :
      {
        policy_name      = k
        name             = application_group.name
        key              = "${k}-${application_group.name}"
        applications     = application_group.apps
        updatable_policy = p.updatable
      } if trimsuffix(ks, "-${application_group.name}") == k

    ]
  ])

  apps_to_fetch = flatten([
    for k, application_group in data.oci_network_firewall_network_firewall_policy_application_group.application_group : [
      for _, app in application_group.apps :
      {
        name                       = app
        network_firewall_policy_id = application_group.parent_resource_id
        # policy-name = trimsuffix(ks, "-${application_group.name}") so the key will be policyname-appname
        key = format("%s-%s", trimsuffix(k, "-${application_group.name}"), app)
      }
    ]
  ])

  flattened_applications = flatten([
    for k, p in var.policies : p.updatable ? [
      for ka, a in try(p.applications.definitions, []) :
      merge(a, { policy_name = k, key = "${k}-${ka}", name = ka })
      ] : [
      for ks, app in data.oci_network_firewall_network_firewall_policy_application.application :
      {
        policy_name      = k
        key              = "${k}-${app.name}"
        name             = app.name
        updatable_policy = p.updatable
        protocol         = app.type
        type             = app.icmp_type
        icmp_code        = app.icmp_code
      } if trimsuffix(ks, "-${app.name}") == k
    ]
  ])
}

data "oci_network_firewall_network_firewall_policy_application_groups" "all_application_groups" {
  for_each                   = var.policies
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy[each.key].id
}

data "oci_network_firewall_network_firewall_policy_application_group" "application_group" {
  for_each                   = { for k, v in local.application_groups_to_fetch : "${v.key}" => v }
  network_firewall_policy_id = each.value.network_firewall_policy_id
  name                       = each.value.name
}
data "oci_network_firewall_network_firewall_policy_application" "application" {
  for_each = { for k, v in local.apps_to_fetch : "${v.key}" => v }

  network_firewall_policy_id = each.value.network_firewall_policy_id
  name                       = each.value.name
}

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
  for_each = { for _, v in local.flattened_application_groups : "${v.key}" => v }

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
