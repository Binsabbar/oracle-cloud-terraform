output "vcn" {
  value = oci_core_vcn.vcn
}

output "private_subnets" {
  value = { for subnet_name, value in oci_core_subnet.private_subnet :
    subnet_name => value
  }
}

output "public_subnets" {
  value = { for subnet_name, value in oci_core_subnet.public_subnet :
    subnet_name => value
  }
}

output "lpg" {
  value = { for gateway_name, value in oci_core_local_peering_gateway.peering_gateway :
    gateway_name => value
  }
}

# output "attached_views_order" {
#   description = "The order in which views are attached to the resolver (from highest to lowest priority)"
#   value = [
#     for p in sorted_priorities : {
#       name     = [for v in local.views_array : v.name if v.priority == p][0]
#       view_id  = [for v in local.views_array : v.view_id if v.priority == p][0]
#       priority = p
#     }
#   ]
# }

output "attached_views" {
  description = "views attached to the resolver"
  value       = local.sorted_views
}

output "views_array" {
  description = "views attached to the resolver"
  value       = local.views_array
}

output "sorted_priorities" {
  description = "views attached to the resolver"
  value       = local.sorted_priorities
}