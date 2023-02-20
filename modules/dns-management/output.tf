output "dns_record" {
  value = { for items, value in oci_dns_rrset.dns_rrset :
    records => value
  }
}