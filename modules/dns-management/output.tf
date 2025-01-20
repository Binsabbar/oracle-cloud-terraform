output "dns_configuration" {
  description = "Hierarchical structure of DNS views, their zones, and records"
  value = {
    protected_views = {
      for view_key, view in data.oci_dns_view.protected_view : view_key => {
        view_details = {
          name           = view.display_name
          compartment_id = view.compartment_id
          id             = view_key
        }
        zones = {
          for zone_key, zone in oci_dns_zone.private_dns_zone_protected_view : zone_key => {
            if zone.view_id == view_key
            zone_details = {
              name           = zone.name
              compartment_id = zone.compartment_id
            }
            records = {
              for record_key, record in oci_dns_rrset.dns_rrset_protected_view : record_key => {
                if record.zone_name_or_id == zone.name
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
      }
    }

    custom_views = {
      for view_key, view in oci_dns_view.custom_view : view_key => {
        view_details = {
          name           = view.display_name
          compartment_id = view.compartment_id
          id             = view.id
        }
        zones = {
          for zone_key, zone in oci_dns_zone.private_dns_zone_custom_view : zone_key => {
            if zone.view_id == view.id
            zone_details = {
              name           = zone.name
              compartment_id = zone.compartment_id
            }
            records = {
              for record_key, record in oci_dns_rrset.dns_rrset_custom_view : record_key => {
                if record.zone_name_or_id == zone.name
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
      }
    }
  }
}