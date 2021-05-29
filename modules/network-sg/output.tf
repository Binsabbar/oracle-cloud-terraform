output "networks_sg" {
  value = { for key, value in oci_core_network_security_group.security_group : key => value.id }
}
