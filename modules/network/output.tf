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

