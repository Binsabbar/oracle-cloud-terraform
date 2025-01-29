variable "compartment_id" { type = string }
variable "name" {
  type        = string
  description = "The name of the NFW"
}
variable "availability_domain" {
  type        = string
  description = "The AD to deploy FW in"
}

variable "networking" {
  type = object({
    subnet_id          = string
    ipv4address        = string
    ipv6address        = optional(string, "")
    security_group_ids = set(string)
  })
}

variable "active_firewall_policy_name" {
  type        = string
  description = "name of the key in the var.network_firewall_policy"
}

variable "policies" {
  type = map(object({
    name = string
    rules = list(object({
      name                  = string
      source_addresses      = set(string)
      destination_addresses = set(string)
      action                = string
    }))
  }))
}
