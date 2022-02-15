output "instances" {
  value = {
    for k, instance in oci_core_instance.instances : k => {
      id           = k.id
      primary_vnic = {
        primary_ip = [
          for ip in data.oci_core_private_ips.primary_vnic_primary_private_ip[k].private_ips : {
            id         = ip.id
            ip_address = ip.ip_address
            vnic_id    = ip.vnic_id
            subnet_id  = ip.subnet_id
            public_ip  = instance.public_ip
          } if ip.is_primary
        ][0]
        secondary_ips = {
          for ip in local.flattened_primary_vnic_secondary_ips :
          ip.secondary_ip_key => {
            id         = oci_core_private_ip.primary_vnic_additional_ips["${ip.instance_key}:primary_vnic:${ip.secondary_ip_key}"].id
            ip_address = oci_core_private_ip.primary_vnic_additional_ips["${ip.instance_key}:primary_vnic:${ip.secondary_ip_key}"].ip_address
          } if ip.instance_key == k
        }
      }
      secondary_vnics = {
        for vnic in local.flattened_secondary_vnics :
        vnic.vnic_key => {
          primary_ip = [
            for ip in data.oci_core_private_ips.secondary_vnic_attachment_ips["${vnic.instance_key}:${vnic.vnic_key}"].private_ips : {
              id         = ip.id
              ip_address = ip.ip_address
              vnic_id    = ip.vnic_id
              subnet_id  = ip.subnet_id
            } if ip.is_primary
          ][0]
          secondary_ips = {
            for ip in local.flattened_secondary_vnic_secondary_ips :
            ip.secondary_ip_key => {
              id         = oci_core_private_ip.secondary_vnic_additional_ips["${ip.instance_key}:${ip.vnic_key}:${ip.secondary_ip_key}"].id
              ip_address = oci_core_private_ip.secondary_vnic_additional_ips["${ip.instance_key}:${ip.vnic_key}:${ip.secondary_ip_key}"].ip_address
            } if ip.instance_key == k
          }
        } if vnic.instance_key == k
      }
    }
  }
}
