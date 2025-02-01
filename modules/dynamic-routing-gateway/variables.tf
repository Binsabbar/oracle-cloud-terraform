variable "compartment_id" { type = string }
variable "drg" {
  type = object({
    name = string
    attachments = optional(map(object({
      id        = string
      type      = string
      optionals = optional(map(string), {})
    })), {})
  })
}