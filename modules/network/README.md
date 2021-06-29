- [Network](#network)
  - [What is created as part of the module?](#what-is-created-as-part-of-the-module)
  - [Note about Route Table and Security List](#note-about-route-table-and-security-list)
  - [Limitations](#limitations)
  
# Network
Probably one of the most important modules after [identity](../identity/README.md). Most of the objects created in Oracle Cloud must belong to a network in order to use it. This module configurs virtual cloud network. Read more about VCN concepts [here](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm). Have a look at `variables.tf` to check the list of required variables.

## What is created as part of the module?
The module will create a single virtual cloud network, with no subnet by default. You can pass a map of subnet configurations for public and private subnets.

When the VCN is created, the following objects are created by default:
* DHCP: Used by default for both public and private subnets
* Internet Gateway (defaultInternetGateway): it is attached to any created public subnet
* NAT GAteway (defaultNatGateway): It is attached to any created private subnet
* Route Table (defaultRouteTable): if no route table id is passed for a public subnet, this route table is used for the public subnet. The public default route table is configurable using `public_route_table_rules` variable.
* Private Route Table (defaultPrivateRouteTable): if no route table id is passed for a private subnet, this route table is used for the private subnet. The private default route table is configurable using `private_route_table_rules` variable.

When a subnet is created, some default objects are created:
* Public security list: Enables incoming ICPM from the internet. When `allowed_ingress_ports` has ports, it allow incoming connection from the internet to `allowed_ingress_ports`. The default value is `[]` empty list. You still can pass another security list ids and it will be concatenated to this list. Lastly, you can use optionals key to pass list of tcp and udp egress ports to internet in `allow_tcp_egress_to_ports` and `allow_udp_egress_to_ports` under `optionals.
* Private security list: By default empty, but you can use optionals key to pass list of tcp and udp egress ports to internet in `allow_tcp_egress_to_ports` and `allow_udp_egress_to_ports` under `optionals. You still can pass another security list ids and it will be concatenated to this list.

## Note about Route Table and Security List
* Route Table: the module will use default route table if not route table id is passed during creation of subnet. You can either configure the defaul route tables using `xxxxxx_route_table_rules` variables, or you can set different route table for each subnet you create using `route_table_id` key of the subnet you create.
* Security List: the module will create defaul subnet list rules, and you can enhance that further by creating your own security list and pass them as IDs to the subnet.

## Limitations
* The module does not support VCN Peering.

VCN without any subnet:
```h
source = PATH_TO_MODULE

  compartment_id        = "ocixxxxxx.xxxxxx.xxxxx"
  name                  = "vcn-no-subnet"
  cidr_block            = "192.168.0.0/16"
  allowed_ingress_ports = []
  private_subnets       = {}
  public_subnets        = {}
```

VCN with two private subnets and one public subnet that has its own routing table.
```h
module "network" {
  source = PATH_TO_MODULE

  compartment_id        = "ocixxxxxx.xxxxxx.xxxxx"
  name                  = "vcn"
  cidr_block            = "192.168.0.0/16"
  allowed_ingress_ports = [80, 443]

  private_subnets = {
    "private-a" = {
      cidr_block        = "192.168.2.0/24"
      security_list_ids = ["ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx"]
      optionals         = {}
    },
    "private-b" = {
      cidr_block        = "192.168.3.0/24"
      security_list_ids = ["ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx"]
      optionals         = {
        allow_tcp_egress_to_ports = [80, 443]
        allow_udp_egress_to_ports = [30900]
      }
    },
  }

  public_subnets = {
    "public" = {
      cidr_block        = "192.168.3.0/24"
      security_list_ids = ["ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx"]
      optionals         = {
        route_table_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
    }
  }
}
```