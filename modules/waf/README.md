- [WAF Policies](#waf-policies)
  - [Limitations](#limitations)
- [Example](#example)

# WAF Policies
Using the module is straightforward, however, usage of this module is not recommended due to the fact that updating a WAF policy takes long. Moreover, the resource definition is complicated. Refer to WAAS resource definition in [terraform](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/waas_waas_policy). Read more about Oracle WAF Policies [here](https://docs.oracle.com/en-us/iaas/Content/WAF/Tasks/managingwaf.htm). This module is useful if you want a simple and quick WAF with default configuration and managed by Oracle.

***Note: the module was not tested and used in a production environment, due to the above complication.*
**

## Limitations
* Customisation of the module is extremly limited, espcially WAF configuration.

# Example
Creating two security list with the following rules:
  
```h
module "waf" {
  source = PATH_TO_MODULE

  policies = {
    "my-waf-policy" = {
      additional_domains = ["ms1.example.com", "ms2.example.com"]
      compartment_id     = "ocixxxxxx.xxxxxx.xxxxx"
      domain             = "example.com"

      origins = {
        label = "backend"
        uri   = "x.x.x.x" # must be public IP so oracle WAF can reach it
      }

      policy_config = {
        certificate_id                = "ocixxxxxx.xxxxxx.xxxxx"
        cipher_group                  = "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256"
        is_behind_cdn                 = true
        is_cache_control_respected    = true
        is_origin_compression_enabled = true
        is_response_buffering_enabled = true
        is_sni_enabled                = true
        optionals                     = {}
      })
      optionals = {}
    }
  }
}

```