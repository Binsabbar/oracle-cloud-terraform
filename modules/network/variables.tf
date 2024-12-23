variable "tenancy_ocid" { type = string }
variable "compartment_id" { type = string }
variable "name" {
  type        = string
  default     = "vcn"
  description = "The name of the VCN which will be used in FQDN"
}

variable "cidr_block" {
  type        = string
  default     = "192.168.0.0/16"
  description = "The CIDR block for the VCN"
}

variable "ipv6" {
  type = object({
    enabled        = bool
    oci_allocation = optional(bool, false)
    cidr_block     = optional(list(string), [])
  })
  default = {
    enabled        = false
    oci_allocation = false
    cidr_block     = []
  }

  description = <<EOF
    map of object to configure IPv6
      enabled       : set to true to enable IPv6 support for the VCN
      oci_allocation: set to true to enable automatic allocation of IPv6 CIDR on the VCN
      cidr_block    : The IPv6 CIDR block for the VCN
  EOF
}
# Gateways
variable "nat_gateway" {
  type = object({
    enable        = bool
    public_ip_id  = string
    block_traffic = bool
    optionals     = map(string)
  })
  default = {
    enable        = true
    block_traffic = false
    public_ip_id  = ""
    optionals     = {}
  }

  description = <<EOF
    map of object to configure NAT
      enable       : set to true to create a NAT Gateway and automatically add route rule in private route table
      public_ip_id : ID of reserved public IP. Leave empty if you want oci to create random public IP
      block_traffic: disable traffic on the NAT (but keep it in the route table!)
      optionals        : map of optional values
        route_table_id: route table id to be used instead of default one
  EOF
}

variable "internet_gateway" {
  type = object({
    enable    = bool
    optionals = map(string)
  })

  default = {
    enable    = true
    optionals = {}
  }
  description = <<EOF
    map of object to configure Internet Gateway
      enable: set to true to create a Internet Gateway and automatically add route rule in public route table
      optionals        : map of optional values
        route_table_id: route table id to be used instead of default one
  EOF
}

variable "service_gateway" {
  type = object({
    enable                          = bool
    service_id                      = string
    route_rule_destination          = string
    add_route_rule_in_public_subnet = bool
    optionals                       = map(string)
  })

  default = {
    enable                          = false
    service_id                      = ""
    route_rule_destination          = ""
    add_route_rule_in_public_subnet = false
    optionals                       = {}
  }

  description = <<EOF
    map of object to configure Service Gateway
      enable    : set to true to create a Service Gateway and automatically add route rule in private route table
      service_id: The Services ID (check OCI Service Gateway docs)
      optionals        : map of optional values
        route_table_id: route table id to be used instead of default one
  EOF
}

# Subnets
variable "private_subnets" {
  type = map(object({
    name              = string
    cidr_block        = string
    security_list_ids = list(string)
    optionals         = any # map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # route_table_id = string # id of custom route table
  }))

  description = <<EOL
  map of subnet object configurations. Key is used as subnet name in the FQDN (as dns_label)
    name             : the display name of the subnet (node dns_label can't be updated)
    cidr_block       : the cidr block for the subnet
    security_list_ids: list of security ids to be attached to the subnet
    optionals        : map of optional values
      route_table_id: route table id to be used instead of default one
  EOL
}

variable "public_subnets" {
  type = map(object({
    name              = string
    cidr_block        = string
    security_list_ids = list(string)
    optionals         = map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # route_table_id = string # id of custom route table
  }))

  description = <<EOL
  map of subnet object configurations. Key is used as subnet name in the FQDN (as dns_label)
    name             : the display name of the subnet (node dns_label can't be updated)
    cidr_block       : the cidr block for the subnet
    security_list_ids: list of security ids to be attached to the subnet
    optionals        : map of optional values
      route_table_id: route table id to be used instead of defaul one
  EOL
}

# Routing
variable "public_route_table_rules" {
  type = map(object({
    destination       = string
    destination_type  = string
    network_entity_id = string
  }))
  default = {}

  description = <<EOL
  map of route table configurations. Key is used as route table rule name
    destination      : IP or OCID of oracle service (oci-phx-objectstorage)
    destination_type : The type of destination above
    network_entity_id: The OCID for the route rule's target
  EOL
}

variable "private_route_table_rules" {
  type = map(object({
    destination       = string
    destination_type  = string
    network_entity_id = string
  }))
  default = {}

  description = <<EOL
  map of route table configurations. Key is used as route table rule name
    destination      : IP or OCID of oracle service (oci-phx-objectstorage)
    destination_type : The type of destination above
    network_entity_id: The OCID for the route rule's target
  EOL
}

# Security
variable "default_security_list_rules" {
  type = object({
    public_subnets = object({
      tcp_egress_ports_to_all    = list(number)
      tcp_ingress_ports_from_all = list(number)
      udp_egress_ports_to_all    = list(number)
      udp_ingress_ports_from_all = list(number)
      enable_icpm_from_all       = bool
      enable_icpm_to_all         = bool
    })
    private_subnets = object({
      tcp_egress_ports_to_all    = list(number)
      tcp_ingress_ports_from_vcn = list(number)
      udp_egress_ports_to_all    = list(number)
      udp_ingress_ports_from_vcn = list(number)
      enable_icpm_from_vcn       = bool
      enable_icpm_to_all         = bool
    })
  })

  default = {
    public_subnets = {
      tcp_egress_ports_to_all    = []
      tcp_ingress_ports_from_all = []
      udp_egress_ports_to_all    = []
      udp_ingress_ports_from_all = []
      enable_icpm_from_all       = false
      enable_icpm_to_all         = false
    }
    private_subnets = {
      tcp_egress_ports_to_all    = []
      tcp_ingress_ports_from_vcn = []
      udp_egress_ports_to_all    = []
      udp_ingress_ports_from_vcn = []
      enable_icpm_from_vcn       = false
      enable_icpm_to_all         = false
    }
  }
  description = "map of objects for allowed tcp and udp ingress/egress ports to the internet (0.0.0.0/0)"
}

variable "local_peering_gateway" {
  type = map(object({
    name              = string
    peer_id           = string
    route_table_id    = string
    destination_cidrs = set(string)
  }))

  default     = {}
  description = <<EOF
    map of object to configure Local Peering Gateway
      name              : The name of the peering gateway
      peer_id           : The OCID of the target Peering ID in the other VCN
      route_table_id    : route table of the local peering gateway (it will be attached to LPG)
      destination_cidrs : list of other subnets/vcns cidrs to route trafic to from via this gateway. This will create route table rules in both
      default public and private route tables. Leave empty if you intend to configure them manually.
  EOF
}
