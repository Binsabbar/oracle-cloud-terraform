# Network Firewall

This module allows you to create  Network Firewalls and manage their policies and security rules. Read more about Network Firewall concepts at [oracle](https://docs.oracle.com/en-us/iaas/Content/network-firewall/overview.htm).

You can manage the entire firewall policies and rules as code. Currently the only supported rule is [**Security Rule**](https://docs.oracle.com/en-us/iaas/Content/network-firewall/policy-components.htm#components) is supported

Using this module you can create multiple firewalls at once.

## Regions and Availability Domains Deployment
To deploy a regional firewall, then do not set `var.firewalls.*.availability_domain`. Read more about [Regions and Availability Domains Deployment](https://docs.oracle.com/en-us/iaas/Content/network-firewall/overview.htm#enter-topic-id)


## Policy Rules
Due to some limitations with how `for_each` works in Terraform, the rule ordering is disabled by default. However, you can enable the ordering by setting `var.policies.*.order_rules` to `true`. Ensure you only set it to `true`, only if the rules have already been created in the policy, otherwise, the `apply` might fail. The ordering in the `var.policies.*.rules` is important, since it reflects the order of the rules in the policy.

For example, if the rules is defined as following:
```h
rules = [
  {
    name = "rule-1"
    ...
    ...
  }
  {
    name = "rule-3"
    ...
    ...
  }
  {
    name = "rule-2"
    ...
    ...
  }
]
```
then the rules will be ordered as following:
1. `rule-1`
2. `rule-3`
3. `rule-2`


It is recommended that you define your rules in `var.policies.*.rules` and set `var.policies.*.order_rules` to `false`. Once the rules are created, set `var.policies.*.order_rules` to `true` to apply the ordering

## Assign Policy to 
Since you can define multiple policies, you can use the policy `KEY` in the variable input defeinition `var.policies[KEY]` as a reference to the active policy. Note that, you MUST assign a policy to firewall, even if the policy is empty
```h
policies = {
  empty-policy = { <----- this is the policy key that you need to refer to in the firewall
    name = "empty-policy-display-name"  <------ this is just a display name
    compartment_id = "ocid.xxx.xxx.xxx"
  }
}
```
Then you can use the key `empty-policy` to assign this policy to the firewall.

```h
firewalls = {
    "firewall-1" = {
      compartment         = "ocixxxxxx.xxxxxx.xxxxx"
      name                = "firewall"
      policy_name         = "empty-policy" <------ the key of the policy created 
      availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
      networking = {
        subnet_id          = "ocixxxxxx.xxxxxx.xxxxx"
        ipv4address        = "10.0.1.12/32"
        security_group_ids = ["ocixxxxxx.xxxxxx.xxxxx"]
      }
    }
  }

```

Note that, you can assign the same policy to multiple firewalls.

##
## Note about `INSPECT` Action
When `var.policies.*.rules[*].action` is set to `INSPECT`, then you must set `var.policies.*.rules[*].inspection` to one of the following [`"INTRUSION_DETECTION"`, `"INTRUSION_PREVENTION"`].

## Limitation
Currently the module does **not** provide support for the following:
* [**Decryption Rules**](https://docs.oracle.com/en-us/iaas/Content/network-firewall/policy-components.htm#components): Decryption rules decrypt traffic from a specified source, destination, or both.
* [**Tunnel Inspection Rules**](https://docs.oracle.com/en-us/iaas/Content/network-firewall/policy-components.htm#components): Inspect traffic mirrored to an Oracle resource using the OCI Virtual Test Access Point (VTAP) service.
### Limitation with Rules Ordering
`for_each` is used to create the rules, however, terraform does not run them sequentially, which does not guarantee rule-1 is created before rule-2 is created. So when the ordering is assigned, it could fail since `rule-1` is not yet created. That's why the `var.policies.*.order_rules` is introduced.

We are exploring the option of introducing a new terraform resource in [oci provider](https://github.com/oracle/terraform-provider-oci) that is dedicated for the rule ordering, this way, the dependencies can be clearly defined between rule creation and rule ordering.

## Using this module


Example of `input.tf` for this module:

```h
module "firewall" {
  source              = PATH_TO_MODULE

  firewalls = {
    "firewall-1" = {
      compartment         = "ocixxxxxx.xxxxxx.xxxxx"
      name                = "firewall"
      policy_name         = "empty-policy"
      availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
      networking = {
        subnet_id          = "ocixxxxxx.xxxxxx.xxxxx"
        ipv4address        = "10.0.1.12/32"
        security_group_ids = ["ocixxxxxx.xxxxxx.xxxxx"]
      }
    }

    "firewall-2" = {
      compartment         = "ocixxxxxx.xxxxxx.xxxxx"
      name                = "firewall"
      policy_name         = "policy-1"
      availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
      networking = {
        subnet_id          = "ocixxxxxx.xxxxxx.xxxxx"
        ipv4address        = "10.0.2.12/32"
        security_group_ids = ["ocixxxxxx.xxxxxx.xxxxx"]
      }
    }
  }


  policies = {
    empty-policy = {  
      name = "empty-policy-name"
      compartment_id = "ocid.xxx.xxx.xxx"
    }

    policy-1 = {
      name      = "policy-1-name"
      address_lists = {
        address-list-1 = ["192.168.10.0/24"]
        address-list-2 = ["10.1.10.0/24"]
        address-list-3 = ["172.1.10.0/24"]
      }
      url_lists = {
        ubuntu = ["ubuntu.com", "*.ubuntu.com"]
        google = ["google.com", "*.google.com"]
      }

      services = {
        definitions = {
          "http" = {
            port_ranges = [{ min_port = 80, max_port = 80 }, { min_port = 8080, max_port = 8080 }]
            type        = "TCP"
          }
          "service-2" = {
            port_ranges = [{ min_port = 80, max_port = 80 }, { min_port = 8080, max_port = 8080 }]
            type        = "UDP"
          }
        }
        lists = {
          "web"      = ["http", "service-2"]
          "tcp-http" = ["http"]
        }
      }

      applications = {
        definitions = {
          "icmp-echo" = {
            protocol = "ICMP"
            type     = 0
          }
        }
        lists = {
          "icmp" = ["icmp-echo"]
        }
      }

      order_rules = false
      rules = [
        {
          name       = "rule-0"
          inspection = "INTRUSION_DETECTION"
          action     = "INSPECT"
        },
        {
          name              = "rule-2"
          service_lists     = ["web"]
          application_lists = ["icmp"]
          action            = "ALLOW"
        },
        {
          name             = "rule-4"
          source_addresses = ["address-list-1"]
          service_lists    = ["tcp-http"]
          action           = "ALLOW"
        },
        {
          name                  = "rule-1"
          source_addresses      = ["address-list-1"]
          destination_addresses = ["address-list-1"]
          action                = "ALLOW"
        },
        {
          name                  = "rule-3"
          source_addresses      = ["address-list-1", "address-list-3"]
          destination_addresses = []
          service_lists         = []
          url_lists             = ["google"]
          action                = "ALLOW"
        }
      ]
    }
  }
}
```