locals {
  /*
  Converts: { "group1" = [user1, user2], "group2" = [user1] }
  TO
  [
    {member = user1, group = group1},
    {member = user2, group = group1},
    {member = user1, group = group2}
  ]
  */
  flattened_memberships = flatten([
    for group, members in var.memberships : [
      for member in members : {
        member = member
        group  = group
      }
    ]
  ])
  flattened_compartment_policies = flatten([
    for compartment_name, compartment_data in var.compartments : [
      for policy, statements in compartment_data.policies : {
        name        = policy
        compartment = compartment_name
        statements  = statements
      } if length(statements) > 0
    ] if length(compartment_data.policies) > 0
  ])

  groups                  = [for group in keys(var.memberships) : oci_identity_group.groups[group]]
  service_accounts_groups = [for key, sa in var.service_accounts : oci_identity_group.service_accounts_groups[sa.name]]

  depends_on = concat(local.groups, local.service_accounts_groups)

}

resource "oci_identity_compartment" "compartments" {
  for_each       = var.compartments
  name           = each.key
  description    = "${each.key} compartment"
  compartment_id = each.value.root_compartment
  freeform_tags = {
    "type"      = "identity"
    "managedby" = "terraform"
  }
  enable_delete = var.enable_delete
}

# Noraml User's account that has emails
resource "oci_identity_group" "groups" {
  for_each = var.memberships

  compartment_id = var.tenant_id
  description    = each.key
  name           = each.key

  freeform_tags = {
    "type"      = "identity groups"
    "managedby" = "terraform"
  }
}

resource "oci_identity_user" "users" {
  # toset() to remove duplicated users.
  for_each = toset(flatten(values(var.memberships)))

  compartment_id = var.tenant_id
  description    = each.key
  name           = each.key
  email          = each.key

  freeform_tags = {
    "type"      = "identity users"
    "managedby" = "terraform"
  }
}

resource "oci_identity_user_group_membership" "user_group_membership" {
  for_each = { for membership in local.flattened_memberships : "${membership.group}-${membership.member}" => membership }

  group_id = oci_identity_group.groups[each.value.group].id
  user_id  = oci_identity_user.users[each.value.member].id
}


# Service Accounts - to associate a policy with a service account, the
# service account must belong to a group
resource "oci_identity_user" "service_accounts" {
  for_each = var.service_accounts

  compartment_id = var.tenant_id
  description    = each.value.name
  name           = each.value.name
}

resource "oci_identity_group" "service_accounts_groups" {
  for_each = var.service_accounts

  compartment_id = var.tenant_id
  description    = each.value.name
  name           = each.value.name
}

resource "oci_identity_user_group_membership" "service_accounts_group_membership" {
  for_each = var.service_accounts

  group_id = oci_identity_group.service_accounts_groups[each.key].id
  user_id  = oci_identity_user.service_accounts[each.key].id
}

resource "oci_identity_user_capabilities_management" "service_accounts_capabilities_management" {
  for_each = var.service_accounts

  user_id = oci_identity_user.service_accounts[each.key].id

  can_use_api_keys             = lookup(each.value.capabilities, "api_keys", false)
  can_use_auth_tokens          = lookup(each.value.capabilities, "auth_tokens", false)
  can_use_console_password     = lookup(each.value.capabilities, "console_password", false)
  can_use_customer_secret_keys = lookup(each.value.capabilities, "customer_secret_keys", false)
  can_use_smtp_credentials     = lookup(each.value.capabilities, "smtp_credentials", false)
}


# Some policies have to be applied at the tenancy level so compartment_id must be the tenant_id
resource "oci_identity_policy" "tenancy_policies" {
  for_each = var.tenancy_policies != null ? { (var.tenancy_policies.name) = var.tenancy_policies.policies } : {}

  compartment_id = var.tenant_id
  description    = "tenancy policies"
  name           = each.key
  statements     = each.value

  depends_on = [local.depends_on]
}

# Other policies cab be applied directly to the compartment
resource "oci_identity_policy" "policies" {
  for_each = { for val in local.flattened_compartment_policies : val.name => val }

  compartment_id = oci_identity_compartment.compartments[each.value.compartment].id
  description    = "Policy for ${each.value.compartment}"
  name           = "${each.key}-policy"
  statements     = each.value.statements

  depends_on = [local.depends_on]
}


## IdP Mapping
resource "oci_identity_idp_group_mapping" "idp_group_mapping" {
  for_each = var.identity_group_mapping

  group_id             = each.value.oci_group_id
  identity_provider_id = each.value.idp_ocid
  idp_group_name       = each.value.idp_group_name
}

# Cost-tracking tags
resource "oci_identity_tag_namespace" "tag_namespace" {
  for_each       = var.tags == null ? {} : { ns = var.tags }
  compartment_id = var.tenant_id
  name           = var.tags.name
  description    = var.tags.description
  is_retired     = false
}

resource "oci_identity_tag" "tags" {
  for_each         = var.tags.keys
  tag_namespace_id = oci_identity_tag_namespace.tag_namespace.id
  name             = each.key
  description      = each.value.description
  is_cost_tracking = each.value.is_cost_tracking
}