output "dns_record" {
  value = {
    record = oci_dns_rrset.dns_rrset.items
  }
}