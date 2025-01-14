# DNS Management System

This module allows you to create a full DNS management system. Read more about DNS concepts at [oracle](https://docs.oracle.com/en-us/iaas/Content/DNS/Concepts/dnszonemanagement.htm). It consists of thress components, DNS Views , DNS Zones and DNS Records.

## Using this module

In order to use this module, you need to have a compartement and VCN to create DNS Views, DNS Zone and DNS Record. Check `variables.tf` to understand what each variable means and what to pass.

## Example for this module:

```h
module "dns" {
  source         = PATH_TO_MODULE
  
  private_dns = {
    protected_views = {
      "prod_vcn_protected_views" = {
        view_id        = "ocid1.dnsview.oc1..example1"
        compartment_id = "ocid1.compartment.oc1..example1"
        zones = {
          "internal-prod" = {
            zone_name = "internal-prod.example.com"
            records = {
              "app1" = {
                domain_name = "app1.internal-prod.example.com"
                rdata      = "10.0.1.10"
                # rtype and ttl will use defaults (A and 300)
              }
              "db1" = {
                domain_name = "db1.internal-prod.example.com"
                rdata      = "10.0.1.20"
                rtype      = "A"
                ttl        = 600
              }
            }
          }
          "internal-staging" = {
            zone_name = "internal-staging.example.com"
            records = {
              "app1-stage" = {
                domain_name = "app1.internal-staging.example.com"
                rdata      = "10.0.2.10"
              }
            }
          }
        }
      }
    }
  
    custom_views = {
      "dev_vcn_custom_view" = {
        view_name      = "development_view"
        compartment_id = "ocid1.compartment.oc1..example2"
        zones = {
          "dev-zone" = {
            zone_name = "dev.example.com"
            records = {
              "test-app" = {
                domain_name = "test-app.dev.example.com"
                rdata      = "10.0.3.10"
              }
              "test-db" = {
                domain_name = "test-db.dev.example.com"
                rdata      = "10.0.3.20"
                rtype      = "A"
                ttl        = 900
              }
            }
          }
        }
      }
      "qa_vcn_custom_view" = {
        view_name      = "qa_view"
        compartment_id = "ocid1.compartment.oc1..example3"
        zones = {
          "qa-zone" = {
            zone_name = "qa.example.com"
            records = {
              "qa-app" = {
                domain_name = "qa-app.qa.example.com"
                rdata      = "10.0.4.10"
                rtype      = "A"
                ttl        = 450
              }
              "qa-api" = {
                domain_name = "api.qa.example.com"
                rdata      = "10.0.4.15"
              }
            }
          }
        }
      }
    }
  }
}

```
