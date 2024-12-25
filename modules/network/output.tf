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

output "vcn_attached_views" {
  value = {
    for name, compartment in data.oci_identity_compartments.compartments : name => {
      views = {
        for compartment_id in [for c in compartment.compartments : c.id] :
        compartment_id => try(
          data.oci_dns_views.compartment_views[compartment_id].views,
          []
        )
      }
    }
  }
}