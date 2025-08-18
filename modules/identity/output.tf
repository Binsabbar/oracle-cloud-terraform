output "compartments" {
  value = oci_identity_compartment.compartments
}

output "groups" {
  value = oci_identity_group.groups
}

output "service_accounts_groups" {
  value = oci_identity_group.service_accounts_groups
}