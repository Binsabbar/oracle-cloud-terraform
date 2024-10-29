- [Instances](#instances)
  - [Using Flex Shapes](#using-flex-shapes)
- [Assign Public IP to an instnace](#assign-public-ip-to-an-instnace)
- [Booting from an existing Boot Volume](#booting-from-an-existing-boot-volume)
- [Boot Volume Backup](#boot-volume-backup)
- [User Metadata](#user-metadata)
  - [Limitations](#limitations)
  - [Examples](#examples)
  
# Instances
The module iterates over a list of instances as input, and create them. Check `variables.tf` to understand the type of inputs this module accepts.

Each object in the input list represent an instance that can have its own configuration, such as which compartment, subnet it belongs to, or which security group is attached to.

Using this module you can attach multiple VNICs to your instance. Moreover, you can assign secondary IP (e.g as floating IP) to each of VNIC.

## Using Flex Shapes
You have the options to use AMD/Intel flex shapes. Just set `flex_shape_config` key in `var.instances.*.config` varible per instance. The variable `flex_shape_config` should have the following two keys `ocpus` and `memory_in_gbs`. See example below.

Note that, Flex Shape works only with AMD shape `VM.Standard.E3.Flex` and `VM.Standard.E4.Flex`, and Intel `VM.Standard3.Flex`.

Leave `flex_shape_config` empty `{}` if it is not needed.

# Assign Public IP to an instnace
To attach public IP to any private IP created in this module, you have to do that in `public_ip` module. Refer to `public_ip` module for how to attach private IP to public IP. Using this module output, you can get the private ip OCID and use it in `public_ip` module.

# Booting from an existing Boot Volume 
It is possible to boot a new instance from an existing boot volume using the `optionals` key in the `instances` map. If not set, a new boot volume will be created from scratch and used. In order to boot from an existing bootVolume set
`instances[*].optionals.boot_volume_id` and `instances[*].optionals.boot_source_type = "bootVolume`.

# Boot Volume Backup
By default no backup schedule will be created for the boot volume. You need to create a backup policy in this module in `var.boot_volume_backup_policies`, then attach it to the instance `instances[*].optionals.reference_to_backup_policy_key_name` variable. This way, a backup will be scheduled for the boot volume of the instance. See example below. Please notes that the value of `reference_to_backup_policy_key_name` must be the same name of the key used in the `var.boot_volume_backup_policies`.

# User Metadata
To pass script to run during cloud init phase, use the `user_data` parameter in the instance, which is part of the `optionals` parameter. See example below

## Limitations
* Advance Configuration of the instance is not yet possible using this module. The only configuration acceptable are the ones defined in `variables.tf`.

## Examples
To create 2 instances:
```h
locals {
  instances = {
    "prod-jumpbox" = {
      name                        = "jumpbox-production"
      availability_domain_name    = "ocixxxxxx.xxxxxx.xxxxx"
      fault_domain_name           = "ocixxxxxx.xxxxxx.xxxxx"
      compartment_id              = "ocixxxxxx.xxxxxx.xxxxx"
      volume_size                 = 500
      autherized_keys             = "ssh-rsa xxxxxxxxxxxxxxxxxxxxxx\n ssh-rsa xxxxxxxxxxxxxxxxxxxxxx"
      state                       = "RUNNING"
      config = {
        shape    = "ocixxxxxx.xxxxxx.xxxxx"
        flex_shape_config = {
          ocpus         = 8
          memory_in_gbs = 32
        }
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
        availability_config   = { 
          recovery_action             = "RESTORE_INSTANCE"
          is_live_migration_preferred = false
        }
      }
      secondary_vnics = {}
      optionals = {
        boot_source_type = "bootVolume"
        boot_volume_id   = "ocid1.bootvolume.oc1.xxxxxxxxxxxxxxxxxxxxxxx"
        user_data        = "BASE64_CLOUD_INIT_SCRIPT_GOES_HERE"
      }
      agent_plugins = {
        is_bastion_enabled                         = false
        is_oracle_java_management_service_enabled  = true
        is_vulnerability_scanning_enabled          = true
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
        flex_shape_config = {}
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
      optionals = {
        reference_to_backup_policy_key_name = "my-backup"
      }
    }
}

module "instances" {
  source = PATH_TO_MODULE

  instances = local.instances
  boot_volume_backup_policies = {
    "my-backup" = {
      compartment_id     = "ocixxxxxx.xxxxxx.xxxxx"
      name               = "My Backup policy"
      destination_region = "" # leave empty if you do not have another region in oci
      schedules = {
        "daily" = {
          backup_type       = "INCREMENTAL"
          period            = "ONE_DAY"
          retention_seconds = 3600 * 24 # one day
          optionals = {
            hour_of_day = 23
          }
        }
        "weekly" = {
          backup_type       = "FULL"
          period            = "ONE_WEEK"
          retention_seconds = 3600 * 24 * 7 # one week
          optionals = {
            hour_of_day = 0
            day_of_week = "FRIDAY"
          }
        }
        "monthly" = {
          backup_type       = "FULL"
          period            = "ONE_MONTH"
          retention_seconds = 3600 * 24 * 30 # # one month
          optionals = {
            hour_of_day  = 0
            day_of_week  = "SUNDAY"
            day_of_month = 28
          }
        }
        "yearly" = {
          backup_type       = "FULL"
          period            = "ONE_YEAR"
          retention_seconds = 3600 * 24 * 30 * 12 # # one year
          optionals = {
            hour_of_day  = 0
            day_of_week  = "SUNDAY"
            day_of_month = 30
            month        = "DECEMBER"
          }
        }
      }
    }
  }
}
```
