- [Identity](#identity)
  - [Using this module](#using-this-module)
    - [Creating users and groups](#creating-users-and-groups)
      - [Example: if you need to create 4 users and map them to two groups](#example-if-you-need-to-create-4-users-and-map-them-to-two-groups)
    - [Mapping IdP groups to OCI groups](#mapping-idp-groups-to-oci-groups)
    - [Creating service accounts](#creating-service-accounts)
    - [Important Node about groups and service accounts](#important-node-about-groups-and-service-accounts)
    - [Creating compartments](#creating-compartments)
    - [Creating Tenancy policies](#creating-tenancy-policies)
    - [Complete Example:](#complete-example)


# Identity
This module manages compartments, users, groups and policies for the account, read more about IAM at [oracle](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/overview.htm).

## Using this module
This module is flexible, and depends on what you pass to it. Refer to `variables.tf` to understand what the module accepts. Please continue reading to understand some concepts around this module.

### Creating users and groups
* Using this module you can create users and groups. __**You will have to map a user to group**__ **in order to create a user**. ***A user must always belong to a group during the lifecyle of user***. However, you can create empty groups.
* A user can belong to multiple groups at the sametime, and the module will ensure the user is only created in the system once.
* User value must be a valid email address. This value will be used as `email` value in oracle cloud. This is intentional design of this module.

#### Example: if you need to create 4 users and map them to two groups

Users:
* Abdullah
* Abeer
* Anwar
* Mohammed

Groups:
* portfolio-a
* portfolio-b
* admins

Memberships:

* portfolio-a contains Abdullah and Anwar
* portfolio-b contains Abeer and Mohammed
* admins contains all members above

To achieve the above, pass the following to the module
```h
locals {
  users = {
    "abdullah" = "abdullah@email.com"
    "abeer"    = "abeer@email.com"
    "anwar"    = "anwar@email.com"
    "mohammed" = "mohammed@email.com"
  }

  memberships = {
    "portfolio-a" = [
      local.users.abdullah,
      local.users.anwar
    ]

    "portfolio-b" = [
      local.users.abeer,
      local.users.mohammed
    ]

    "admins" = [
      local.users.abdullah,
      local.users.anwar,
      local.users.abeer,
      local.users.mohammed
    ]
  }
}

module "IAM" {
  source = PATH_TO_MODULE

  tenant_id = "oci.xxxxxxxxx.xxxxxx"
  memberships = local.memberships
}
```

### Mapping IdP groups to OCI groups
When connecting to IdP for SSO. You can map IdP groups to OCI groups using this module. To do that, you need to create groups in a module and the mapping in a different module. For example as following:

```
locals {
  users = {
    "abdullah" = "abdullah@email.com"
    "abeer"    = "abeer@email.com"
    "anwar"    = "anwar@email.com"
    "mohammed" = "mohammed@email.com"
  }

  memberships = {
    "portfolio-a" = [
      local.users.abdullah,
      local.users.anwar
    ]

    "portfolio-b" = [
      local.users.abeer,
      local.users.mohammed
    ]

    "admins" = [
      local.users.abdullah,
      local.users.anwar,
      local.users.abeer,
      local.users.mohammed
    ]
  }
}

module "IAM" {
  source = PATH_TO_MODULE

  tenant_id = "oci.xxxxxxxxx.xxxxxx"
  memberships = local.memberships
}

module "idp_mapping" {
  source = PATH_TO_MODULE

  tenant_id = "oci.xxxxxxxxx.xxxxxx"
  identity_group_mapping = {
    "admins" = {
      idp_group_name = "sso-oci-admin"
      oci_group_id   = module.IAM.groups.admins.id
      idp_ocid       = "oci.xxxxxxxxxx."
    }
    "portfolio-a" = {
      idp_group_name = "sso-oci-portfolio-a"
      oci_group_id   = module.IAM.groups.portfolio-a.id
      idp_ocid       = "oci.xxxxxxxxxx."
    }
    "portfolio-b" = {
      idp_group_name = "sso-oci-portfolio-b"
      oci_group_id   = module.IAM.groups.portfolio-b.id
      idp_ocid       = "oci.xxxxxxxxxx."
    }
  }
}
```

***note that I created `module.IAM` to create groups, then created `module.idp_mapping` to map oci groups to idp groups.***

### Creating service accounts
Service accounts are accounts that meant to used by machines. When a service account is created, a group with the same name of the service account is created as well. This allows you to apply policy to the service account using its group name. Since you can't apply policy directly to a user.

***NOTE***: The design of this module does **not** allow you to group multiple service accounts to the same group. This is intentional.

```h
module "IAM" {
  source = PATH_TO_MODULE

  tenant_id = "oci.xxxxxxxxx.xxxxxx"
  service_accounts = {
    "terraform-cli" = { 
      name = "terraform-cli", 
      capabilities = {
        api_keys = true
      }
    }, 
    "github-client" = {
      name = "github-client", 
      capabilities = {
        smtp_credentials = true
      }
    }
  }
}
```

### Important Node about groups and service accounts
Since service accounts will automatically create a group with the same name of the service account, ensure that you do **not** create a group that matches the service account. Otherwise, you will run into an issue.

### Creating compartments
compartment must have a parent compartment. The top level parent compartment is the tenancy itself. You can attach policies to compartment at creation time as well.

Example: Creating 3 compartments with policies

Compartments:
* compartment-a
* compartment-1
* compartment-b
* compartment-2

Relationships:

> tenancy
>> compartment-a
>>>  compartment-1
>
>> compartment-b
>>> compartment-2

To achieve the above, pass the following to the module
```h

locals {
  tenant_id = "oci.xxxxxxxxx.xxxxxx"
}

module "top_level_compartments" {
  source = PATH_TO_MODULE

  tenant_id = local.tenant_id

  compartments = {
    "compartment-a" = {
      parent = local.tenant_id
      policies = {
        "policy-a" = [
          "allow group xxx to manage virtual-network-family in compartment compartment-a",
        ]
      }
    }

    "compartment-b" = {
      parent = local.tenant_id
      policies = {
        "policy-b" = [
          "allow group xxx to manage virtual-network-family in compartment compartment-b",
        ]
      }
    }
  }
}

module "child_compartments" {
  source = PATH_TO_MODULE

  tenant_id = local.tenant_id

  compartments = {
    "compartment-1" = {
      parent = module.top_level_compartments.compartments["compartment-a"].id
      policies = {}
    }

    "compartment-2" = {
      parent = module.top_level_compartments.compartments["compartment-b"].id
      policies = {}
    }
  }
}
```

### Creating Tenancy policies
Some policies must be attached to the tenancy itself, but not to a compartment. To acheive that use `tenancy_policies` variable.

```h
module "tenancy_policies" {
  source = PATH_TO_MODULE

  tenant_id = "oci.xxxxxxxxx.xxxxxx"
  tenancy_policies = {
    name = "my-main-policy"
    policies = [
      "allow **** to manage resource ***** in tenancy"
    ]
  }
}

```

### Complete Example:
```h

locals {
  users = {
    "abdullah" = "abdullah@email.com"
    "abeer"    = "abeer@email.com"
    "anwar"    = "anwar@email.com"
    "mohammed"  = "mohammed@email.com"
  }

  memberships = {
    "portfolio-a" = [
      local.users.abdullah,
      local.users.anwar
    ]

    "portfolio-b" = [
      local.users.abeer,
      local.users.mohammed
    ]

    "admins" = [
      local.users.abdullah,
      local.users.anwar,
      local.users.abeer,
      local.users.mohammed
    ]
  }

  service_accounts = {
    "terraform-cli" = { 
      name = "terraform-cli", 
      capabilities = {
        api_keys = true
      }
    }, 
    "github-client" = {
      name = "github-client", 
      capabilities = {
        smtp_credentials = true
      }
    }
  }

  tenant_id = "oci.xxxxxxxxx.xxxxxx"
}

module "main_iam" {
  source = PATH_TO_MODULE

  tenant_id        = local.tenant_id
  memberships      = local.memberships
  service_accounts = local.service_accounts
  compartments     = {
    "compartment-a" = {
      parent = local.tenant_id
      policies = {
        "policy-a" = [
          "allow group portfolio-a, terraform-cicd to manage virtual-network-family in compartment compartment-a",
        ]
      }
    }

    "compartment-b" = {
      parent = local.tenant_id
      policies = {
        "policy-b" = [
          "allow group portfolio-b, terraform-cicd to manage virtual-network-family in compartment compartment-b",
        ]
      }
    }
  }

  tenancy_policies = {
    name = "my-main-policy"
    policies = [
      "allow admins to manage all-resource in tenancy"
    ]
  }
}

module "child_compartments" {
  source = PATH_TO_MODULE

  tenant_id = local.tenant_id

  compartments = {
    "compartment-1" = {
      parent = module.main_iam.compartments["compartment-a"].id
      policies = {}
    }

    "compartment-2" = {
      parent = module.main_iam.compartments["compartment-b"].id
      policies = {}
    }
  }
}
```

  ### Creating Cost-tracking Defined tags
Manage OCI defined tags for FinOps (supports cost-tracking flags).
Namespace behavior:
- If tag_namespace doesn't have value (deafult is null) namespace won't be created nor the tags
Tag keys: create under the resolved namespace from tag_keys map; each key supports:
- description (optional)
- is_cost_tracking (optional, default false)

  ### Example usage:
  ```h
  tags = {
    name        = "finops"   Name of the namespace
    description = "Cost & billing metadata"  Description of the namespace.
    keys = {
      env       = { description = "Environment", is_cost_tracking = true }
      type      = { description = "Application/Tool", is_cost_tracking = true }
      portfolio = { description = "Product/Portfolio", is_cost_tracking = true }
    }
  }
  ```