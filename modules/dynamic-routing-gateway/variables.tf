variable "compartment_id" { type = string }

variable "drg" {
  type = object({
    name = string
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
    route_tables = optional(map(object({
      name = string
      rules = optional(map(object({
        destination                 = string
        next_hop_drg_attachment_key = string
      })), {})
    })), {})
  })
  description = <<EOF
    object to configure DRG and its attachments
      name                  : name of the DRG
      attachments           : map of objects to configure DRG VCN attachments
        vcn_id              : the network id attached to the DRG
        optionals           : map of extra optional configurations
          drg_route_table_id: drg route table id to be used instead of default one
          route_table_id    : route table id to be used instead of default one
          vcn_route_type    : weather VCN CIDRs or subnet CIDRs which are imported from the attachment, only "VCN_CIDRS" or "SUBNET_CIDRS" is allowed.
  EOF
}
