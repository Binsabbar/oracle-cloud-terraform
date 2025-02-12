output "firewall" {
  value = oci_network_firewall_network_firewall.network_firewall
}

output "policies" {
  value = oci_network_firewall_network_firewall_policy.network_firewall_policy
}

output "test" {
  value = data.oci_network_firewall_network_firewall_policy_address_lists.address_lists
}