# Output for Custom Views
output "custom_views_info" {
  description = "Basic information about created custom DNS views"
  value = {
    for key, view in oci_dns_view.custom_view : key => {
      name           = view.display_name
      compartment_id = view.compartment_id
      id             = view.id
    }
  }
}

# Output for Protected Views
output "protected_views_info" {
  description = "Basic information about protected DNS views"
  value = {
    for key, view in data.oci_dns_view.protected_view : key => {
      name           = view.display_name
      compartment_id = view.compartment_id
      id             = key
    }
  }
}

# Output for Zones
output "zones_info" {
  description = "Basic information about created DNS zones"
  value = {
    custom_view_zones = {
      for key, zone in oci_dns_zone.private_dns_zone_custom_view : key => {
        name           = zone.name
        compartment_id = zone.compartment_id
        view_id        = zone.view_id
      }
    }
    protected_view_zones = {
      for key, zone in oci_dns_zone.private_dns_zone_protected_view : key => {
        name           = zone.name
        compartment_id = zone.compartment_id
        view_id        = zone.view_id
      }
    }
  }
}

# Output for Records
output "records_info" {
  description = "Basic information about created DNS records"
  value = {
    custom_view_records = {
      for key, record in oci_dns_rrset.dns_rrset_custom_view : key => {
        domain = record.domain
        rtype  = record.rtype
        items = [for item in record.items : {
          rdata = item.rdata
          ttl   = item.ttl
        }]
      }
    }
    protected_view_records = {
      for key, record in oci_dns_rrset.dns_rrset_protected_view : key => {
        domain = record.domain
        rtype  = record.rtype
        items = [for item in record.items : {
          rdata = item.rdata
          ttl   = item.ttl
        }]
      }
    }
  }
}