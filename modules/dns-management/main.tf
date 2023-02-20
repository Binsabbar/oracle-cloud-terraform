resource "oci_dns_zone" "dns_zone" {
  for_each       = var.zones
  name           = each.value.name
  compartment_id = var.compartment_id
  zone_type      = var.zone_type
  view_id        = var.view_id
  scope          = var.scope
}

resource "oci_dns_rrset" "dns_rrset" {
  for_each        = var.zones
  domain          = each.value.name
  rtype           = each.value.rtype
  zone_name_or_id = each.value.name
  compartment_id  = var.compartment_id
  view_id         = var.view_id
  scope           = var.scope

  dynamic "items" {
    for_each = each.value.records
    content {
      domain = items.value.domain
      rdata  = items.value.rdata
      rtype  = items.value.rtype
      ttl    = items.value.ttl
    }
  }
}