- [Network Security Group](#network-security-group)
  - [Limitations](#limitations)
  - [Rules and IPs](#rules-and-ips)
- [Example](#example)

# Network Security Group
The module create security groups for the given rules. Read NSG concepts [here](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/networksecuritygroups.htm)

Using this module you can configure an NSG and customise rules for each group. Have a look at `variables.tf` to check what the module expect.

## Limitations
* IP Protocols are limited only to TCP and UDP
* Destination or Source are limited to type `CIDR_BLOCK` (IP address only)
* All rules are stateful.
* No support for setting the source port (Port is limited to destination of packet)

## Rules and IPs
Though when using the module, a list of IPs are passed to a single rule, behind the scene, each IP results in a single rule creation. For example,
if you pass one group that has 3 rules, and each rule contains 5 IPs, the total number of rules created by the module for the group is 15 rules.

# Example
The usage of this module is simple. You just need to create a map of groups, where each group has map of rules objects.

Creating two security groups with the following rules:
* Group 1:
  * Rule 1: allow TCP ingress to IPs ["192.168.100.12", "192.168.100.12"] to port 9090
  * Rule 2: allow TCP ingress to IPs ["192.168.100.14", "192.168.100.16"] to port 9091
  * Rule 3: allow TCP egress from IPs ["192.168.100.12", "192.168.100.12"] to port range 8000-8002
* Group 2:
  * Rule 1: allow UDP ingress from IPs ["192.168.200.12", "192.168.200.13"] to port 30091
  * Rule 2: allow TCP ingress from IPs ["192.168.200.12", "192.168.100.12"] to port 9000

```h
module "network_secuirty_groups" {
  source = PATH_TO_MODULE

  vcn_id                  = "ocixxxxxx.xxxxxx.xxxxx"
  compartment_id          = "ocixxxxxx.xxxxxx.xxxxx"
  network_security_groups = {
    "group_1" = {
      "rule_1" = {
        direction = "INGRESS"
        protocol  = "tcp"
        port      = { min : 9090, max : 9090 }
        ips       = ["192.168.100.12", "192.168.100.12"]
      }
      "rule_2" = {
        direction = "INGRESS"
        protocol  = "tcp"
        port      = { min : 9091, max : 9091 }
        ips       = ["192.168.100.14", "192.168.100.16"]
      }
      "rule_1" = {
        direction = "EGRESS"
        protocol  = "tcp"
        port      = { min : 8000, max : 8002 }
        ips       = ["192.168.100.12", "192.168.100.12"]
      }
    }
    
    "group_2" = {
      "rule_1" = {
        direction = "INGRESS"
        protocol  = "udp"
        port      = { min : 30091, max : 30091 }
        ips       = ["192.168.200.12", "192.168.200.13"]
      }
      "rule_2" = {
        direction = "INGRESS"
        protocol  = "tcp"
        port      = { min : 9000, max : 9000 }
        ips       = ["192.168.200.12", "192.168.100.12"]
      }
    }

  }
}    
```

***Note: The above results in creating total of 6 rules for Group 1 and 4 rules for Group 2***