variable "drg" {
  type = object({
    name           = string
    compartment_id = string
    drg_route_table = map(object({
      name                             = string
      enable_import_route_distribution = optional(bool, false)
      enable_ecmp                      = optional(bool, false)

      rules = map(object({
        destination_cidr        = string
        next_hop_attachement_id = string
      }))
    }))
  })
}

variable "drg_attachment" {
  type = object({
    name = string

    network_details = optional(map(object({
      id   = string
      type = string
    })), {})
  })
}