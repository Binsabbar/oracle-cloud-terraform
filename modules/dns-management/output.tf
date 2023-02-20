output "dns_record" {
  value = {
    record = oci_dns_rrset.items.domain
  }
}