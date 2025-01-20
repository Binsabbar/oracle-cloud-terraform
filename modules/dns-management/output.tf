output "custom_views_info" {
  value = {
    for v_key, view in var.private_dns.custom_views : v_key => {
      view_key = v_key
      zones = {
        for z_key, zone in view.zones : z_key => {
          z_key     = z_key
          zone_name = zone.zone_name
          records = {
            for r_key, record in zone.records : r_key => {
              r_key       = r_key
              domain_name = record.domain_name
              rdata       = record.rdata
              rtype       = record.rtype
              ttl         = record.ttl
            }
          }
        }
      }
    }
  }
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
