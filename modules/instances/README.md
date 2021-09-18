- [Instances](#instances)
  - [Limitations](#limitations)
  - [Examples](#examples)
  
# Instances
The module iterates over a list of instances as input, and create them. Check `variables.tf` to understand the type of inputs this module accepts.

Each object in the input list represent an instance that can have its own configuration, such as which compartment, subnet it belongs to, or which security group is attached to.

## Limitations
* The current setup allows an instance to be part of one subnet. Attaching an instance to multiple network interface is not yet supported in this module.
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
      }
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
      }
    }
}

module "instances" {
  source = PATH_TO_MODULE

  instances = local.instances
}
```