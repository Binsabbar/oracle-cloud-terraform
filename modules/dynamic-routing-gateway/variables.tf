variable "drg" {
  type = object({
    name           = string
    compartment_id = string
  })
}

variable "drg_attachments" {
  type = object({
    name = string
    network_details = optional(map(object({
      id   = string
      type = string
    })), {})
    optionals = optional(map(string), {})
  })
}