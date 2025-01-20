output "custom_views_info" {
  value = {
    for v_key, view in oci_dns_view.custom_view : v_key => {
      view_key = v_key
      view_name = view.display_name
      zones = {
        for z_key, zone in oci_dns_zone.private_dns_zone_custom_view : z_key => {
          z_key = z_key
          zone_name = zone.name
          records = {
            for r_key, record in oci_dns_rrset.dns_rrset_custom_view : r_key => {
              r_key = r_key
              domain = record.domain
              rtype = record.rtype
              items = record.items
            } if split("-", r_key)[0] == v_key && split("-", r_key)[1] == split("-", z_key)[1]
          }
        } if split("-", z_key)[0] == v_key
      }
    }
  }
  description = "Structured output of DNS configuration with transformed keys"
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
