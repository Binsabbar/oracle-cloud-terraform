resource "oci_dns_zone" "dns_zone" {
  for_each       = var.zones
  name           = each.value.name
  compartment_id = var.compartment_id
  zone_type      = var.zone_type
  view_id        = var.view_id
  scope          = var.scope
}

resource "oci_dns_rrset" "dns_rrset" {
  for_each        = var.records
  domain          = each.value.domain_name
  rtype           = each.value.rtype
  zone_name_or_id = each.value.zone_name
  compartment_id  = var.compartment_id
  view_id         = var.view_id
  scope           = var.scope
  # items {
  #   domain = each.value.domain_name
  #   rdata  = each.value.rdata
  #   rtype  = each.value.rtype
  #   ttl    = each.value.ttl
  # }
}