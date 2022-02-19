# V2:
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
  * `public_ip` and `private_ip` changed to include vnic info, and primary ip. Also `private_ip` is renamed to `ip_address`:
  ```
  "primary_vnic" = {
      "primary_ip" = {
        "id" = "ocid1.privateip.oc1.xxxxxxxxxxxxxxxx"
        "ip_address" = "xxx.xxx.xxx.xxx"
        "public_ip" = "xxx.xxx.xxx.xxx"
        "subnet_id" = "ocid1.subnet.oc1.xxxxxxxxxxxxxxx"
        "vnic_id" = "ocid1.vnic.oc1.xxxxxxxxxxxxxxx"
      }
      "secondary_ips" = {
        ...
        ...
      }
  }
  ```
* `instances` modules input is updated as following:
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