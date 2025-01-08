locals {

  zones_records = [
    for zone_name, zone in var.zones : [
      for record_key, record in zone.records : {
        key         = record_key
        zone_name   = zone_name
        domain_name = record.domain_name
        rdata       = record.rdata
        rtype       = record.rtype
        ttl         = record.ttl
      }
    ]
  ]

  flattened_records = flatten(local.zones_records)

  formatted_records = {
    for record in local.flattened_records : record.key => {
      zone_name   = record.zone_name
      domain_name = record.domain_name
      rdata       = record.rdata
      rtype       = record.rtype
      ttl         = record.ttl
    }
  }
}

resource "oci_dns_zone" "dns_zone" {
  for_each       = var.zones
  name           = each.key
  compartment_id = var.compartment_id
  zone_type      = var.zone_type
  view_id        = var.view_id
  scope          = var.scope
}

resource "oci_dns_rrset" "dns_rrset" {
  for_each        = local.formatted_records
  domain          = each.value.domain_name
  rtype           = each.value.rtype
  zone_name_or_id = each.value.zone_name
  compartment_id  = var.compartment_id
  view_id         = var.view_id
  scope           = var.scope

  items {
    domain = each.value.domain_name
    rdata  = each.value.rdata
    rtype  = each.value.rtype
    ttl    = each.value.ttl
  }

  depends_on = [
    oci_dns_zone.dns_zone
  ]
}