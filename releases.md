# v2.12.0:
## **New**
* `instances`: Add option to enable/disable cloud agent plugins.
  * new `agent_plugins` setting
* `network`: Configure VCN DNS Resolver with attaching Private Views that is retrieved from a list of selected compartments.
  * new `tenancy_ocid` setting
  * new `update_dns_resolver` setting
  * new `attach_views_compartments` setting

## **Fix**
None

## _**Breaking Changes**_
None


# v2.11.0:
## **New**
* `network-sg`: add support for all rule types: ip cidrs, service cidrs and nsg ids.
  * see the example in the module for how to use the new variable.
  * the default value is `CIDR_BLOCK` to ensure backward compatibility.
  * add new variables:
    * `var.network_security_groups.*.*.type`
    * `var.network_security_groups.*.*.ips`
    * `var.network_security_groups.*.*.nsg_ids`
    * `var.network_security_groups.*.*.service_cidrs`
  * They are optional based on the type, if type is not set, then `var.network_security_groups.*.*.ips` becomes mandatory.
* `kubernetes`: Ability to add user defined tags for OKE nodes by using the optional variable `node_pools.*.defined_tags`

## **Fix**
* `instances`: Ignore changes made to `metadata.user_data` in any instance, since changing the value will destroy and recreate the instance. 
```h
resource "oci_core_instance" "instances" {
  ...
  ...
  metadata = {
    ssh_authorized_keys = each.value.autherized_keys
    user_data           = lookup(each.value.optionals, "user_data", null)
  }
  lifecycle {
    ignore_changes = [
      metadata["user_data"]   <------------------------------ note this 
    ]
  }
}
```

## _**Breaking Changes**_
None


# v2.10.0:
## **New**
* `network-sg`: change input type to support ports range in `var.network_security_groups.*.ports` variable.

## **Fix**
None

## _**Breaking Changes**_
* `network-sg` modules input for `network_security_groups` is updated. The subkey `port` is replaced with `ports` and it is now a map of two objects `max` and `min`. 

```h
network_security_groups = {
    "group_1" = {
      "rule_1" = {
        direction = "INGRESS"
        protocol  = "tcp"
        port      = { min : 9090, max : 9090 }
        ips       = ["192.168.100.12", "192.168.100.12"]
      }
    }
}
```
* Currently there is no easy migration path for this change, since the terraform resource name is updated. However, destroying and recreating the rules is the best and fastest way to do it, however, it might impact your networks for few minutes. Alternatively, reference the new release in a new module definition, and migration your rules one by one.


# v2.9.0:
## **New**
* `identity`: add new argument `capabilities` in `var.service_accounts` variable.

## **Fix**
* Correct `path` argument by `source` argument to specify the module path in `identity` module usage examples in `README.md`.

## _**Breaking Changes**_
* `identity` modules input for `service_accounts` is updated. A new key `capabilities` is now required under `var.service_accounts.*`.
  * Add `capabilities` and set its value to `{}`.

from:
```h
module "identity" {
  ...
  service_accounts = toset(["terraform-cli"])
  ...
}
```
to:
```h
module "identity" {
  ...
  service_accounts = {
    "terraform-cli" = { 
      name = "terraform-cli", 
      capabilities = {}
    }
  }
  ...
}
```

# v2.8.0:
## **New**
* `instances`: add new argument `availability_config`. for VM migration during infrastructure maintenance events

## **Fix**
None

## _**Breaking Changes**_
* `instances` modules input is updated. A new key `availability_config` is now required under `var.instances.*.config`.
  * Add `is_live_migration_preferred` and set its value to `true`. Example of partial instance object. 
  * Add `recovery_action` and set its value to `RESTORE_INSTANCE`. Example of partial instance object. 
```
 instances = {
   ...
   ...
   ...
      network_sgs_ids = [
          "ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx",
        ]
        primary_vnic = {
          primary_ip = ""
          secondary_ips = {}
        }
        availability_config   = {   <--------------------------------------------------- note this block 
          recovery_action             = "RESTORE_INSTANCE"  
          is_live_migration_preferred = false
        }
      }

    ...
    ...
```

# v2.7.1:
## **New**
None

## **Fix**
Change VNIC's `skip_source_dest_check` to an optional variable input.

## _**Breaking Changes**_
None

# v2.7.0:
## **New**
* `instances`: add `boot_volume_backup_policies` to the input as optional value.
* `instances`: add `instances[*].optional.reference_to_backup_policy_key_name` to the `instance` variable input as optional value to enable scheduled backup of boot volume

## **Fix**
None

## _**Breaking Changes**_
None

# v2.6.1:
## **New**
* `instances`: add `hostname_label` to the output

## **Fix**
None

## _**Breaking Changes**_
None


# v2.6.0:
## **New**
* `dns`: add ability to manage dns records in oci dns service

## **Fix**
None

## _**Breaking Changes**_
None

# v2.5.0:
## **New**
* `network`: Add route rule to the default public route table when service gateway is enabled (note this is optional to add it to public subnet). Please refer to [known issues with service gateway in public subnet](https://docs.oracle.com/en-us/iaas/Content/Network/Reference/known_issues_for_networking.htm#sgw-route-rule-conflict) before enabling it in public subnet.

## **Fix**
None

## _**Breaking Changes**_
* `network` modules input is updated. A new key `add_route_rule_in_public_subnet` is now required under `var.service_gateway`.
  * Add `add_route_rule_in_public_subnet` and set its value to `false`. See module's readme for full example.
```
service_gateway = {
  enable = true
  service_id = "ocid1.service.oc1.xxxxxxx"
  route_rule_destination = "all-pox-services-in-oracle-services-network"
  add_route_rule_in_public_subnet = false <-------------------------------------- note this line
  optionals     = {
    route_table_id = "oci.xxxxxxxxx"
  }
}
``` 

# v2.4.1:
## **New**
None
## Fix
* Ignore changes made to `options[0].service_lb_subnet_ids`, since changing the value can destory the cluster. OKE does not allow updating Service LoadBalncer Subnet anymore, and, it is still there in the API. However, you are not restircted to deploy service load balancer to another subnet using annotations (https://github.com/oracle/oci-cloud-controller-manager/blob/master/docs/load-balancer-annotations.md).
* add `prevent_destroy` to true, to avoid destorying the cluster due to changes made outside of Terraform.

## _**Breaking Changes**_
None

# v2.4.0:
## **New**
* `Kubernetes`:
  * Ability to create autoscaling node pool with node `size=0` and the size param is ignored by Terraform state.
## Fix
None

## _**Breaking Changes**_
None


# v2.3.1:
## **New**
* `Mysql`:
  * Add ignore_changes feature to `admin_password` param.
## Fix
* `Mysql`: fix `retention_in_days` value in README.md.

## _**Breaking Changes**_
None

# v2.3.0:
## **New**
* `instances`:
  * Ability to pass `user_data` as param for instance creation.
* `networks`:
  * Ability to attach a route table to (NAT, Internet, Service) gateways.
  * Add Local Peering Gateway option.
## _**Breaking Changes**_
None

# v2.2.0:
## **New**
* `instances`: Add an option to boot a new instance from an existing bootVolume (check doc for `instance` module).
## _**Breaking Changes**_
None

# v2.1.1:
## Fix
* `instances`: fix `assign_private_dns_record` default value. The release in `v2.0.1` broke the functionality. This value has to always be true since we always set the hostname label.

## _**Breaking Changes**_
None

# v2.1.0:
_**Please see breaking changes section before upgrading.**_
## **New**
* `instances`: add posibility to use flex shape configuration

## _**Breaking Changes**_
* `instances` modules input is updated. A new key `flex_shape_config` is now required under `var.instances.*.config`.
  * Add `flex_shape_config` and set its value to `{}`. Example of partial instance object. See module's readme for full example.
```
"instance-a" = {
  name                     = "instance-a"
  availability_domain_name = "ocixxxxxx.xxxxxx.xxxxx"
  fault_domain_name        = "ocixxxxxx.xxxxxx.xxxxx"
  compartment_id           = "ocixxxxxx.xxxxxx.xxxxx"
  volume_size              = 500
  autherized_keys          = "ssh-rsa xxxxxxxxxxxxxxxxxxxxxx\n ssh-rsa xxxxxxxxxxxxxxxxxxxxxx"
  state                    = "RUNNING"
  config = {
    shape    = "ocixxxxxx.xxxxxx.xxxxx"
    flex_shape_config = {}    <-------------------------------------------------------------------- note this line
    ...
    ...
    ...
    ...
  }
}
```
# v2.0.1:
## Fix
* `instances`: fix output of module (use `instance.id` instead of `k.id`)
* `instances`: fix `assign_private_dns_record` default value.
  
# v2.0:
_**Please see breaking changes section before upgrading.**_

## **New** 
* `vault` module to manage KMS (only for key management service). 
* `volume` module to manage extra volume attachments and backup. #7 
* (`object-storage`) Allow to add `lifecycle-rules` to buckets. #13 
* (`instance`) Ability to add multiple secondary IPs to primary VNIC #14 #15 
* (`instance`) Ability to add multiple secondary VNICs and multiple private IPs #8
* (`public-ip`) Ability to attach public ip to a given private IP #16 
* (`network`) Ability to 
  * configure `NAT Gateway` (enable/disable, block traffic, assign reserved public IP) #19 
  * configure `Internet Gateway` (enable/disable gateway) #19 
  * Create `Service Gateway`. #20 
* (`kubernetes`) Ability to use `Flex Shape` 
* (`kubernetes`) Ability to change node volume size
* (`kubernetes`) Ability to use NextGen Cluster #23 
* (`identity`) Ability to map IdP groups to oci groups. #27 

## _**Breaking Changes**_
* `public_ip` module input name is changed from `ips` to `untracked_ips`.
  * This is to distinguish public IPs that will be managed by Terraform (private IP assignment are not tracked by Terraform). This is used in service like `NLB`. 
  * output of module changed. Previously named `ips` renamed to `untracked_ips`
* `object-storage` module input is updated to include configuration for `lifecycle` managements.
  * Add the following key to every bucket created `lifecycle-rules = {}`. To configure rules, refer to module's readme.
* `network` module input is updated as following:
  * `allowed_ingress_ports` is removed and replaced by the new key `tcp_ingress_ports_from_all` in `default_security_list_rules.public_subnets`.
    * `allowed_ingress_ports` was applied only to **public subnet security list** as TCP ingress. Whatever value you had there add it to `default_security_list_rules.public_subnets.tcp_ingress_ports_from_all`
  * `tcp_ingress_ports_from_vcn` and `udp_ingress_ports_from_vcn` are added to `default_security_list_rules.private_subnets`
  * NAT Gateway and Internet Gateway resource name has changed. Run the following command manually to update the state names
  
  Internet Gateway Resource 
  ```
  terraform state mv module.NETWORK_MODULE_NAME.oci_core_internet_gateway mv module.module.NETWORK_MODULE_NAME.oci_core_internet_gateway\[0\]
  ```
  Nat Gateway Resource 
  ```
  terraform state mv module.NETWORK_MODULE_NAME.oci_core_nat_gateway mv module.module.NETWORK_MODULE_NAME.oci_core_nat_gateway\[0\]
  ```
  Public Route Table Resource 
  ```
  terraform state mv module.NETWORK_MODULE_NAME.oci_core_default_route_table.public_route_table module.NETWORK_MODULE_NAME.oci_core_default_route_table.public_route_table\[\"igw=true\"\]
  ```
  Private Route Table Resource
  ```
  terraform state mv module.NETWORK_MODULE_NAME.oci_core_route_table.private_route_table module.NETWORK_MODULE_NAME.oci_core_route_table.private_route_table\[\"natgw=true:svcgw=false\"\]
  ```
* `instances` modules output is updated:
  * `public_ip` and `private_ip` changed to include vnic info, and primary ip. Also `private_ip` is renamed to `ip_address`. The new instance output is like the following:
  from:
  ```
  MY_INSTANCE = {
    private_ip = "xxx.xxx.xxx.xxx"
    public_ip  = "xxx.xxx.xxx.xxx"
  }
  ```
  to
  ```
  MY_INSTANCE = {
    id = ocid.instance.xxxxxxxxxxxxx
    primary_vnic = {
      primary_ip = {
        id = "ocid1.privateip.oc1.xxxxxxxxxxxxxxxx"
        ip_address = "xxx.xxx.xxx.xxx"
        public_ip = "xxx.xxx.xxx.xxx"
        subnet_id = "ocid1.subnet.oc1.xxxxxxxxxxxxxxx"
        vnic_id = "ocid1.vnic.oc1.xxxxxxxxxxxxxxx"
      }
      secondary_ips = {}
    }
    secondary_vnics = {}
  }
  ```
* `instances` modules input is updated as following:
  * input has new attribute `name`. It must be added to instance block, set it to `name = "INSTANCE_NAME"`
  * input has new attribute `optionals`. It must be added to instance block. Set it to `{}`
  * `config` object has new attribute `primary_vnic`.
    * Add the following when upgrading to fix it.
    ```
    ...
    ...
    config = { 
      primary_vnic = {  <------ this line start
        primary_ip = "", 
        secondary_ips = {}
      } <------ this line end
    }
    ...
    ...
    ```
  * `secondary_vnics` is new attribute to instance object.
    * Add the following to instance object.
    ```
    {
      ...
      ...
      config = {
      ...
      ...
      }
      secondary_vnics = {} <------ this line
      ...
      ...
    }
    ```
* (`kubernetes`) The following new variables are added (Only supported for NextGen Clusters. Do not upgrade to V2 if you are using old clusters). 
  * `k8s_version` is renamed to `cluster_k8s_version`
  * `endpoint_config`: set it to existing configuration (take it from UI)
  * `node_pools[].volume_size_in_gbs`: Set it to `50` to keep current configuration as is.
  * `node_pools[].k8s_version`: Set it to the previous value of `k8s_version` to keep current configuration as is.
  * `node_pools[].flex_shape_config`: Set it to `{}`
  * `node_pools[].node_metadata`: Set it to `{}`

## **Enhancement**
* (`instances`) Allow rename of instance withour recration (breaking change) #6 
  * You need to add `name` attribute to the instance objects you already created.
* (`network`) Allow display name of subnet to be updated (breaking change) #6 
  * You need to add `name` attribute to the subnet objects you already created.
* (`kuberentes`) Ability to set master node version separately from node pool version. #22 
