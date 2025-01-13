# Custom Views Outputs
output "custom_views" {
  description = "Map of all custom DNS views with their zones and records"
  value = {
    for view_key, view in oci_dns_view.custom_view : view_key => {
      view_id        = view.id
      view_name      = view.display_name
      compartment_id = view.compartment_id
      protected      = view.is_protected
      zones = {
        for zone_key, zone in oci_dns_zone.private_dns_zone_custom_view :
        zone_key => {
          zone_id   = zone.id
          zone_name = zone.name
          records = {
            for record_key, record in oci_dns_rrset.dns_rrset_custom_view :
            record_key => record.items[0] if split("-", record_key)[0] == view_key &&
            split("-", record_key)[1] == split("-", zone_key)[1]
          }
        } if split("-", zone_key)[0] == view_key
      }
    }
  }
}

# Protected Views Outputs
output "protected_views" {
  description = "Map of all protected DNS views with their zones and records"
  value = {
    for view_id, view in data.oci_dns_view.protected_view : view_id => {
      view_name      = view.display_name
      compartment_id = view.compartment_id
      protected      = view.is_protected
      zones = {
        for zone_key, zone in oci_dns_zone.private_dns_zone_protected_view :
        zone_key => {
          zone_id   = zone.id
          zone_name = zone.name
          records = {
            for record_key, record in oci_dns_rrset.dns_rrset_protected_view :
            record_key => record.items[0] if split("-", record_key)[0] == split("-", zone_key)[0] &&
            split("-", record_key)[1] == split("-", zone_key)[1]
          }
          } if contains([for item in local.private_dns_zones_protected_veiws :
        item.item_key if item.view_id == view_id], zone_key)
      }
    }
  }
}

# All DNS Records Summary
output "all_dns_records" {
  description = "Flat list of all DNS records across all views and zones"
  value = merge(
    {
      for record_key, record in oci_dns_rrset.dns_rrset_custom_view : record_key => {
        domain    = record.domain
        rtype     = record.rtype
        rdata     = record.items[0].rdata
        ttl       = record.items[0].ttl
        view_type = "custom"
        view_name = oci_dns_view.custom_view[split("-", record_key)[0]].display_name
        zone_name = oci_dns_zone.private_dns_zone_custom_view[join("-", slice(split("-", record_key), 0, 2))].name
      }
    },
    {
      for record_key, record in oci_dns_rrset.dns_rrset_protected_view : record_key => {
        domain    = record.domain
        rtype     = record.rtype
        rdata     = record.items[0].rdata
        ttl       = record.items[0].ttl
        view_type = "protected"
        view_id   = data.oci_dns_view.protected_view[local.private_dns_records_protected_veiws[record_key].view_id].id
        zone_name = oci_dns_zone.private_dns_zone_protected_view[join("-", slice(split("-", record_key), 0, 2))].name
      }
    }
  )
}