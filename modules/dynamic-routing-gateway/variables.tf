variable "gateways" {
  type = object({
    gateways = map(object{
        compartment_id = string
        name = string

        drg_route_tables = map(object{
            name = string
            enable_import_route_distribution = optional(bool, false)
            enable_ecmp = optional(bool, false)

            rules = map(object{
                destination_cidr = string
                next_hop_attachement_id = string
            })
        })

        vcn_attachements = optional(map(object({
            name = string
            vcn_compartment_id = string
            vcn_id = string
            drg_route_table = 
        })), {})

        ipsec_attachements = optional(map(object({
            name = string
            ipsec_id = string
        })), {})

        remote_peering_connection = optional(map(any))

    })
  })
}