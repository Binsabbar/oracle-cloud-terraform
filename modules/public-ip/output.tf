output "ips" {
  value = {
    for key, value in oci_core_public_ip.ip : key => value
  }
}
