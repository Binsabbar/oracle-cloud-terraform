### Private Custom Views Zones
locals {
  private_dns_zones_custom_views = flatten([
    for v_key, view in var.private_dns.custom_views : [
      for z_key, zone in view.zones : {
        zone_key       = z_key
        view_key       = v_key
        zone_name      = zone.zone_name
        compartment_id = view.compartment_id
      }
    ]
  ])

  private_dns_records_custom_views = flatten([
    for v_key, view in var.private_dns.custom_views : [
      for z_key, zone in view.zones : [
        for r_key, record in zone.records : {
          record_key  = r_key
          zone_key    = z_key
          domain_name = record.domain_name
          rdata       = record.rdata
          rtype       = record.rtype
          ttl         = record.ttl
        }
      ]
    ]
  ])
}

resource "oci_dns_view" "custom_view" {
  for_each = var.private_dns.custom_views

  display_name   = each.value.view_name
  compartment_id = each.value.compartment_id
  scope          = "PRIVATE"
}

resource "oci_dns_zone" "private_dns_zone_custom_view" {
  for_each = { for _, item in local.private_dns_zones_custom_views : "${item.zone_key}" => item }

  name           = each.value.zone_name
  compartment_id = each.value.compartment_id
  zone_type      = "PRIMARY"
  view_id        = oci_dns_view.custom_view[each.value.view_key].id
  scope          = "PRIVATE"
}

resource "oci_dns_rrset" "dns_rrset_custom_view" {
  for_each = { for _, item in local.private_dns_records_custom_views : "${item.record_key}" => item }

  domain          = each.value.domain_name
  rtype           = each.value.rtype
  zone_name_or_id = oci_dns_zone.private_dns_zone_custom_view[each.value.zone_key].id

  items {
    domain = each.value.domain_name
    rdata  = each.value.rdata
    rtype  = each.value.rtype
    ttl    = each.value.ttl
  }
}

### Private Protected Views Zones
locals {
  private_dns_zones_protected_views = flatten([
    for v_key, view in var.private_dns.protected_views : [
      for z_key, zone in view.zones : {
        zone_key       = z_key
        view_id        = v_key
        zone_name      = zone.zone_name
        compartment_id = view.compartment_id
      }
    ]
  ])

  private_dns_records_protected_views = flatten([
    for v_key, view in var.private_dns.protected_views : [
      for z_key, zone in view.zones : [
        for r_key, record in zone.records : {
          record_key  = r_key
          zone_key    = z_key
          domain_name = record.domain_name
          rdata       = record.rdata
          rtype       = record.rtype
          ttl         = record.ttl
          view_id     = view.view_id
        }
      ]
    ]
  ])
}

data "oci_dns_view" "protected_view" {
  for_each = { for _, item in var.private_dns.protected_views : item.view_id => item }

  view_id = each.value.view_id
  scope   = "PRIVATE"
}

resource "oci_dns_zone" "private_dns_zone_protected_view" {
  for_each = { for _, item in local.private_dns_zones_protected_views : "${item.zone_key}" => item }

  name           = each.value.zone_name
  compartment_id = each.value.compartment_id
  view_id        = each.value.view_id

  zone_type = "PRIMARY"
  scope     = "PRIVATE"

  lifecycle {
    precondition {
      condition     = data.oci_dns_view.protected_view[each.value.view_id].is_protected
      error_message = "ERROR: view ${each.value.view_id} is not protected, only protected view ids are allowed in private_dns.protected_views input"
    }
  }
}

resource "oci_dns_rrset" "dns_rrset_protected_view" {
  for_each = { for _, item in local.private_dns_records_protected_views : "${item.record_key}" => item }

  domain          = each.value.domain_name
  rtype           = each.value.rtype
  zone_name_or_id = oci_dns_zone.private_dns_zone_protected_view[each.value.zone_key].id

  items {
    domain = each.value.domain_name
    rdata  = each.value.rdata
    rtype  = each.value.rtype
    ttl    = each.value.ttl
  }
}
