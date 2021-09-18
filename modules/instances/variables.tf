
variable "instances" {
  type = map(object({
    name                     = string
    availability_domain_name = string
    fault_domain_name        = string
    compartment_id           = string
    volume_size              = number
    state                    = string
    autherized_keys          = string
    config = object({
      shape           = string
      image_id        = string
      network_sgs_ids = list(string)
      subnet = object({
        id                         = string,
        prohibit_public_ip_on_vnic = bool
      })
    })
  }))
  description = <<EOF
    map of objects that represent instances to create. The key name is the instance name that is used for FQDN
    availability_domain_name: the name of the availability domain to create instance in
    fault_domain_name       : the name of the fault domain in the availability domain to create instance in
    compartment_id          : ocid of the compartment
    volume_size             : the initial boot volume size in GB
    state                   : RUNNING or STOPPED
    autherized_keys         : single string containing the SSH-RSA keys seperated by \n
    config = object of instance configuration
      shape           : name of the VM shape to be used
      image_id        : ocid of the boot image
      network_sgs_ids : list network security groups ids to be applied to the main interface
      subnet = object for the subnet configuration
        id                         : ocid of the subnet
        prohibit_public_ip_on_vnic : whether to create public IP or not if located in public subnet, set to false if not
      })
    })
  EOF
}