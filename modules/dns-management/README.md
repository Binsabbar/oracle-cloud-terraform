# File Storage System

This module allows you to create a full DNS management system. Read more about DNS concepts at [oracle](https://docs.oracle.com/en-us/iaas/Content/DNS/Concepts/dnszonemanagement.htm). It consists of two components, a DNS Zone and a DNS Record.

## Using this module

In order to use this module, you need to have a compartement and VCN to create the DNS Zone and DNS Record. Check `variables.tf` to understand what each variable means and what to pass.

## Example for this module:

```h
module "dns" {
  source         = PATH_TO_MODULE
  
  compartment_id = COMPARTMENT_OCID
  
  view_id        = VIEW_OCID // Optional if scope is PUBLIC
  
  zones          = {
    // ZONE 1
    "test" = {
      name = "test.com"
    }
    // ZONE 2
    "test-2" = {
      name = "test-2.com"
    }
  }
  
  records       = {
    // RECORD 1
    "test" = {
      domain_name = "*.test.com"
      rtype       = "A"
      zone_name   = "test.com"
      rdata       = "xxx.xxx.xxx.xxx"
      ttl         = 300
    }
    // RECORD 2
    "test-2" = {
      domain_name = "something.test-2.com"
      rtype       = "A"
      zone_name   = "test-2.com"
      rdata       = "xxx.xxx.xxx.xxx"
      ttl         = 300
    }
  }
}

```
