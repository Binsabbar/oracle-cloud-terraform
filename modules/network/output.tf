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
      for view in local.views_array : view.key => {
        "view_id"  = view.view_id
        "priority" = view.priority
      }
      if view.priority == priority
    }
  ]
}