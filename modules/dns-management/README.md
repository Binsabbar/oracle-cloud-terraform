# DNS Management System

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
  "test.com" = {
  // ZONE 1 RECORDS
    records = {
      "web.test.com" = {
        domain_name  = "web.test.com"
        rdata        = "20.xxx.xxx.xxx"
        rtype        = "A"
        ttl          = 300
      }
    }
  }
  // ZONE 2
  "test-2.com" = {
  // ZONE 2 RECORDS
    records = {
      "web.test-2.com" = {
        domain_name    = "web.test-2.com"
        rdata          = "192.xxx.xxx.xxx"
        rtype          = "A"
        ttl            = 300
      }
    }
  }
}
}

```
