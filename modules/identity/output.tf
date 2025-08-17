output "compartments" {
  value = oci_identity_compartment.compartments
}

output "groups" {
  value = oci_identity_group.groups
}

output "service_accounts_groups" {
  value = oci_identity_group.service_accounts_groups
}

output "tag_keys_fqn" {
  description = "Map of short key -> fully-qualified key (namespace.key)."
  value = {
    for k, t in oci_identity_tag.tags :
    k => "${var.tag_namespace.name}.${t.name}"
  }
}