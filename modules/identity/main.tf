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

  groups                  = [for group in keys(var.memberships) : oci_identity_group.groups[group]]
  service_accounts_groups = [for sa in var.service_accounts : oci_identity_group.service_accounts_groups[sa]]

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
  for_each = toset(var.service_accounts)

  compartment_id = var.tenant_id
  description    = each.key
  name           = each.key
}

resource "oci_identity_group" "service_accounts_groups" {
  for_each = toset(var.service_accounts)

  compartment_id = var.tenant_id
  description    = each.key
  name           = each.key
}

resource "oci_identity_user_group_membership" "service_accounts_group_membership" {
  for_each = toset(var.service_accounts)

  group_id = oci_identity_group.service_accounts_groups[each.value].id
  user_id  = oci_identity_user.service_accounts[each.value].id
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
  for_each = { for compartment, config in var.compartments : compartment => config if length(config.policies) > 0 }

  compartment_id = oci_identity_compartment.compartments[each.key].id
  description    = "Polciy for ${each.key}"
  name           = "${each.key}-policy"
  statements     = each.value.policies

  depends_on = [local.depends_on]
}


## IdP Mapping
resource "oci_identity_idp_group_mapping" "idp_group_mapping" {
  for_each = var.identity_group_mapping

  group_id             = each.value.oci_group_id
  identity_provider_id = each.value.idp_ocid
  idp_group_name       = each.value.idp_group_name
}
