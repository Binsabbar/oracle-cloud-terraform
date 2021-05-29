# File Storage System

This module allows you to create a file storage system. Read more about FSS concepts at [oracle](https://docs.oracle.com/en-us/iaas/Content/File/Concepts/filestorageoverview.htm). Use this mount target to create multiple exports in different compartements and availability domains.

You can create [TWO mount targets for your tenancy](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/servicelimits.htm#top). Read more about limits in Oracle Docs. 

## Using this module
In order to use this module, you need to have a compartement to create the FSS in and subnet to create mount target in. Check `variables.tf` to understand what each variable means and what to pass.

Example of `input.tf` for this module:

```h
module "fss" {
  source = PATH_TO_MODULE

  mount_target = {
    hostname_label      = "file-system-mount-target"
    subnet_id           = "ocixxxxxx.xxxxxx.xxxxx"
    nsg_ids             = ["ocixxxxxx.xxxxxx.xxxxx"]
    availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
    compartment_id      = "ocixxxxxx.xxxxxx.xxxxx"
  }

  fss = {
    "file-system-example" = {
      availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
      compartment_id      = "ocixxxxxx.xxxxxx.xxxxx"
      exports = {
        "export-1" = {
          path = "/example-export"
          options = {
            "my-subnets" = {
              source = "192.168.100.12/32"
              access = "READ_ONLY"
              optionals = { 
                require_privileged_source_port = false 
              }
            }
            "client-a-subnets" = {
              source = "192.168.200.12/32"
              access = "READ_ONLY"
              optionals = { 
                require_privileged_source_port = true
                identity_squash                = "NONE"
                anonymous_gid                  = 63334
                anonymous_uid                  = 65334
              }
            }
          }
        }

        "export-2" = {
          path = "/another-export"
          options = {
            "my-subnets" = {
              source = "192.168.100.12/32"
              access = "READ_ONLY"
              optionals = {}
            }
          }
      }
    }
  }
}

```