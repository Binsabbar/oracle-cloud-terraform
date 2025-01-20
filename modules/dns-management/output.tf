output "custom_views_info" {
  value = {
    for v_key, view in oci_dns_view.custom_view : v_key => {
      view_name = view.display_name
      zones = {
        for _, z in oci_dns_zone.private_dns_zone_custom_view : z.name => {
          zone_name = z.name
          records = {
            for _, r in oci_dns_rrset.dns_rrset_custom_view : r.domain => {
              domain = r.domain
              rtype  = r.rtype
              items = [
                for item in r.items : {
                  domain       = item.domain
                  rdata        = item.rdata
                  rtype        = item.rtype
                  is_protected = false
                }
              ]
            } if split("-", r.domain)[0] == v_key && split("-", r.domain)[1] == split("-", z.name)[1]
          }
        } if split("-", z.name)[0] == v_key
      }
    }
  }
  description = "Structured output of DNS configuration with simplified keys"
}
# # Output for Protected Views
# output "protected_views_info" {
#   description = "Basic information about protected DNS views"
#   value = {
#     for key, view in data.oci_dns_view.protected_view : key => {
#       name           = view.display_name
#       compartment_id = view.compartment_id
#       id             = key
#     }
#   }
# }
