variable "compartment_id" { type = string }
variable "name" {
  type    = string
  default = "vaultvcn"
  description = "The name of the VCN which will be used in FQDN"
}

variable "cidr_block" {
  type    = string
  default = "192.168.0.0/16"
  description = "The CIDR block for the VCN"
}

variable "allowed_ingress_ports" {
  type        = list(number)
  default     = [80, 443]
  description = "list of allowed ports for the public subnet that will allow inbound connection to machines in the public subnet"
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
      route_table_id: route table id to be used instead of defaul one
  EOL
}

variable "public_subnets" {
  type = map(object({
    cidr_block        = string
    security_list_ids = list(string)
    optionals         = map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # route_table_id = string # id of custom route table
  }))

  description = <<EOL
  map of subnet object configurations. Key is used as subnet name in the FQDN
    cidr_block       : the cidr block for the subnet
    security_list_ids: list of security ids to be attached to the subnet
    optionals        : map of optional values
      route_table_id: route table id to be used instead of defaul one
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