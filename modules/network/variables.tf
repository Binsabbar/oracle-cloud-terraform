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

#TODO: (Deprecation) this will move to default_security_list_rules in V2
variable "allowed_ingress_ports" {
  type        = list(number)
  default     = []
  description = "list of allowed ports that will allow inbound connection to machines in public subnet for default security list"
}

variable "private_subnets" {
  type = map(object({
    cidr_block        = string
    security_list_ids = list(string)
    optionals         = any # map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # route_table_id = string # id of custom route table
  }))

  description = <<EOL
  map of subnet object configurations. Key is used as subnet name in the FQDN
    cidr_block       : the cidr block for the subnet
    security_list_ids: list of security ids to be attached to the subnet
    optionals        : map of optional values
      route_table_id: route table id to be used instead of default one
  EOL
}

variable "public_subnets" {
  type = map(object({
    cidr_block        = string
    security_list_ids = list(string)
    optionals         = map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # route_table_id = string # id of custom route table
    # allow_tcp_egress_to_ports = list(string) # egress tcp ports to 0.0.0.0/0
    # allow_udp_egress_to_ports = list(string) # egress udp ports to 0.0.0.0/0
  }))

  description = <<EOL
  map of subnet object configurations. Key is used as subnet name in the FQDN
    cidr_block       : the cidr block for the subnet
    security_list_ids: list of security ids to be attached to the subnet
    optionals        : map of optional values
      route_table_id: route table id to be used instead of defaul one
      allow_tcp_egress_to_ports: egress tcp ports to 0.0.0.0/0 to be added to default security list
      allow_udp_egress_to_ports: egress udp ports to 0.0.0.0/0 to be added to default security list
  EOL
}

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

variable "default_security_list_rules" {
  type = object({
    public_subnets = object({
      tcp_egress_ports_to_all = list(number)
      udp_egress_ports_to_all = list(number)
      enable_icpm_from_all    = bool
      enable_icpm_to_all      = bool
      #TODO V2: tcp_ingress_ports_from_all = list(number)
      #TODO V2: udp_ingress_ports_from_all = list(number)
    })
    private_subnets = object({
      tcp_egress_ports_to_all = list(number)
      udp_egress_ports_to_all = list(number)
      enable_icpm_from_vcn    = bool
      enable_icpm_to_all      = bool
    })
  })

  default = {
    public_subnets = {
      tcp_egress_ports_to_all = []
      udp_egress_ports_to_all = []
      enable_icpm_from_all    = false
      enable_icpm_to_all      = false
      #TODO V2: tcp_ingress_ports_from_all = []
      #TODO V2: udp_ingress_ports_from_all = []
    }
    private_subnets = {
      tcp_egress_ports_to_all = []
      udp_egress_ports_to_all = []
      enable_icpm_from_vcn    = false
      enable_icpm_to_all      = false
    }
  }
  description = "map of objects for allowed tcp and udp egress ports to the internet (0.0.0.0/0)"
}