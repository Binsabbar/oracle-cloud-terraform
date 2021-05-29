- [Security List](#security-list)
  - [Limitations](#limitations)
- [Example](#example)

# Security List
The module creates security lists for the given set of rules. Read about Security List concepts [here](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/securitylists.htm). Using this module you can configure a security list and customise rules for each list. Have a look at `variables.tf` to check what the module expect.

## Limitations
* Destination or Source are limited to type `CIDR_BLOCK` (IP address only)
* All rules are stateful.

# Example
Creating two security list with the following rules:
* security list 1:
  * Ingress Rules:
    * Rule 1: allow TCP to IP range "192.168.100.0/24" to port range 9000-9100
    * Rule 2: allow TCP to IP range "192.168.100.0/24" to port 8001
  * Egress Rules:
    * Rule 3: allow TCP from IP range "192.168.200.0/24" to port 8000
* security list 2:
  * Ingress Rules:
    * Rule 1: allow TCP to single IP "192.168.100.12/32" to port 80
    * Rule 2: allow UDP to single IP "192.168.100.12/32" to port 80333
  * Egress Rules:
    * None
* security list 3:
  * Ingress Rules:
    * None
  * Egress Rules:
    * None
  
```h
module "security_lists" {
  source = PATH_TO_MODULE

  vcn_id         = "ocixxxxxx.xxxxxx.xxxxx"
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  security_lists = {
    security_list_1 = {
      ingress_rules = {
        "9000ports" = {
          ports     = { min : 9000, max : 9100 }
          source    = "192.168.100.0/24"
          protocol  = 6
          optionals = {}
        }
        "web-app" = {
          ports     = { min : 8001, max : 8001 }
          source    = "192.168.100.0/24"
          protocol  = 6
          optionals = {}
        }
      }
      egress_rules = {
        "to-subnet-apps" = {
          ports       = { min : 8000, max : 8000 }
          destination = "192.168.200.0/24"
          protocol    = 6
          optionals   = {}
        }
      }
    }
    
    security_list_2 = {
      ingress_rules = {
        "from-singleip-to-80" = {
          ports     = { min : 80, max : 80 }
          source    = "192.168.100.12/32"
          protocol  = 6
          optionals = {}
        }
        "from-single-ip-to-udp" = {
          ports     = { min : 80333, max : 80333 }
          source    = "192.168.100.12/32"
          protocol  = 17
          optionals = {}
        }
      }
      egress_rules = {}
    }
    
    security_list_3 = {
      ingress_rules = {}
      egress_rules  = {}
    }
  }
}

```