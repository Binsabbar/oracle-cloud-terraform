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

output "attached_views_order" {
  description = "The order in which views are attached to the resolver (from highest to lowest priority)"
  value = [
    for priority in local.sorted_priorities : {
      priority = priority
      view_id  = local.priority_map[priority][0]
      name     = [for view in local.views_array : view.key if view.priority == priority][0]
    }
  ]
}

output "attached_views" {
  description = "views attached to the resolver"
  value       = local.sorted_views
}