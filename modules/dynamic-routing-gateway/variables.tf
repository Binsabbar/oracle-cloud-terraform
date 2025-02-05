variable "compartment_id" { type = string }

variable "drg" {
  type = object({
    name = string
    route_tables = optional(map(object({
      name = string
      rules = optional(map(object({
        destination                 = string
        next_hop_drg_attachment_key = string
      })), {})
    })), {})

    vcn_attachments = optional(map(object({
      vcn_id              = string
      name                = string
      drg_route_table_key = optional(string, "")
      route_table_id      = optional(string, "")
      vcn_route_type      = optional(string, "SUBNET_CIDRS")
    })), {})

    none_vcn_attachments_managements = optional(map(object({
      name                = string
      type                = string
      network_id          = string
      compartment_id      = optional(string, "")
      drg_route_table_key = optional(string, "")
    })), {})

    remote_peering_connections = optional(map(object({
      name                = string
      drg_route_table_key = optional(string, "")
      peer_connection = optional(object({
        peer_id          = string
        peer_region_name = string
      }), null)
    })), {}),
  })

  description = <<EOF
    object to configure DRGs, DRG route tables, RPCs, and DRG attachments
      name                            : name of the DRG
      route_tables                    : map of objects to configure DRG route tables
        name                          : name of the DRG route table
        rules                         : map of objects to configure DRG route table rules
          destination                 : the range of IP addresses used for matching when routing traffic
          next_hop_drg_attachment_key : the key of the next hop DRG attachment
      vcn_attachments                 : map of objects to configure DRG VCN attachments
        vcn_id                        : the vcn id attached to the DRG
        name                          : name of the VCN attachment
        drg_route_table_key           : drg route table key to be used instead of default one
        route_table_id                : route table id to be used instead of default one
        vcn_route_type                : weather VCN CIDRs or subnet CIDRs which are imported from the attachment, only "VCN_CIDRS" or "SUBNET_CIDRS" is allowed
      none_vcn_attachments_managements: map of objects to configure non-VCN DRG attachments
        name                          : name of the non-VCN attachment
        type                          : the type of DRG attachment and can be either "IPSEC_TUNNEL", "REMOTE_PEERING_CONNECTION", "VCN", or "VIRTUAL_CIRCUIT"
        network_id                    : the network id attached to the DRG
        compartment_id                : ocid of the compartment
        drg_route_table_key           : drg route table key to be used instead of default one
      remote_peering_connections      : map of objects to configure Remote Peering Connections (RPCs)
        name                          : name of the RPC
        drg_route_table_key           : drg route table key to be used instead of default one
        peer_connection               : object to configure RPC peering with another RPC
          peer_id                     : ocid of the RPC to peer with
          peer_region_name            : name of the region that contains the RPC to peer with
  EOF
}
