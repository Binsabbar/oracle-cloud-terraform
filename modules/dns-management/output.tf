# Output for Custom Views
output "custom_views_info" {
  description = "Info about created custom DNS views"
  value = {
    for v_key, view in oci_dns_view.custom_view : "${v_key}: ${view.id}" => {
      for z_key, zone in oci_dns_zone.private_dns_zone_custom_view["${v_key}-${z_key}"] : z_key => {
        for r_key, record in oci_dns_rrset.dns_rrset_custom_view["${v_key}-${z_key}-${r_key}"] : r_key => record
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
