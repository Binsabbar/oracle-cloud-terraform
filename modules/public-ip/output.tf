output "untracked_ips" {
  value = {
    for key, value in oci_core_public_ip.ip : key => {
      id            = value.id
      ip            = value.ip_address
      private_ip_id = value.private_ip_id
    }
  }
}

output "tracked_ips" {
  value = {
    for key, value in oci_core_public_ip.tracked_ip : key => {
      id            = value.id
      ip            = value.ip_address
      private_ip_id = value.private_ip_id
    }
  }
}
