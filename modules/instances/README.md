- [Instances](#instances)
- [Assign Public IP to an instnace](#assign-public-ip-to-an-instnace)
  - [Limitations](#limitations)
  - [Examples](#examples)
  
# Instances
The module iterates over a list of instances as input, and create them. Check `variables.tf` to understand the type of inputs this module accepts.

Each object in the input list represent an instance that can have its own configuration, such as which compartment, subnet it belongs to, or which security group is attached to.

Using this module you can attach multiple VNICs to your instance. Moreover, you can assign secondary IP (e.g as floating IP) to each of VNIC.

# Assign Public IP to an instnace
To attach public IP to any private IP created in this module, you have to do that in `public_ip` module. Refer to `public_ip` module for how to attach private IP to public IP.

## Limitations
* Advance Configuration of the instance is not yet possible using this module. The only configuration acceptable are the ones defined in `variables.tf`.

## Examples
To create 2 instances:
```h
locals { 
  instances = {
    "prod-jumpbox" = {
      name                     = "jumpbox-production"
      availability_domain_name = "ocixxxxxx.xxxxxx.xxxxx"
      fault_domain_name        = "ocixxxxxx.xxxxxx.xxxxx"
      compartment_id           = "ocixxxxxx.xxxxxx.xxxxx"
      volume_size              = 500
      autherized_keys          = "ssh-rsa xxxxxxxxxxxxxxxxxxxxxx\n ssh-rsa xxxxxxxxxxxxxxxxxxxxxx"
      state                    = "RUNNING"
      config = {
        shape    = "ocixxxxxx.xxxxxx.xxxxx"
        image_id = "ocixxxxxx.xxxxxx.xxxxx"
        subnet   = { 
          id = "ocixxxxxx.xxxxxx.xxxxx"
          prohibit_public_ip_on_vnic = true
        }
        network_sgs_ids = [
          "ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx",
        ]
        primary_vnic = {
          primary_ip = ""
          secondary_ips = {}
        }
      }
      secondary_vnics = {}
    }
    
    "dev-jumpbox" = {
      name                     = "jumpbox-development"
      availability_domain_name = "ocixxxxxx.xxxxxx.xxxxx"
      fault_domain_name        = "ocixxxxxx.xxxxxx.xxxxx"
      compartment_id           = "ocixxxxxx.xxxxxx.xxxxx"
      volume_size              = 500
      autherized_keys          = "ssh xxxxxxxxxxxxxxxxxxxxxx"
      state                    = "RUNNING"
      config = {
        shape    = "ocixxxxxx.xxxxxx.xxxxx"
        image_id = "ocixxxxxx.xxxxxx.xxxxx"
        subnet   = { 
          id = "ocixxxxxx.xxxxxx.xxxxx"
          prohibit_public_ip_on_vnic = true
        }
        network_sgs_ids = [
          "ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx",
        ]
        primary_vnic = {
          primary_ip = "192.168.100.12"
          secondary_ips = {
            "floating_ip_1" = {
              name       = "floating IP"
              ip_address = "192.168.100.200"
            }
          }
        }
      }
      secondary_vnics = {
        "network_a_vnic" = {
          name       = "VNIC in Network A"
          primary_ip = "192.168.130.12"
          subnet_id  = "ocid1.subnet.oc1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
          nsg_ids    = []
          skip_source_dest_check = true
          hostname_label         = "vnic_2"
          secondary_ips = {
            "floating_ip" = {
              name       = "Floating IP in Network A"
              ip_address = "192.168.130.200"
            }
          }
        }
      }
    }
}

module "instances" {
  source = PATH_TO_MODULE

  instances = local.instances
}
```