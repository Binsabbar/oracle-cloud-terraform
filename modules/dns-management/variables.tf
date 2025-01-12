variable "private_dns" {
  type = object({
    protected_views = map(object({
      view_id        = string
      compartment_id = string
      zones = map(object({
        zone_name = string
        records = map(object({
          domain_name = string
          rdata       = string
          rtype       = optional(string, "A")
          ttl         = optional(number, 300)
        }))
      }))
    }))

    custom_views = map(object({
      view_name      = string
      compartment_id = string
      zones = map(object({
        zone_name = string
        records = map(object({
          domain_name = string
          rdata       = string
          rtype       = optional(string, "A")
          ttl         = optional(number, 300)
        }))
      }))
    }))
  })
}

