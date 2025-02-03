variable "compartment_id" { type = string }
variable "drg" {
  type = object({
    name = string
    attachments = optional(map(object({
      id        = optional(string)
      type      = string
      optionals = optional(map(string), {})
    })), {})
  })
description = <<EOF
    object to configure DRG and its attachments
      name       : name of the DRG
      attachments: map of objects to attachment
        id       : The network id for the VCN
        type     : The type of attachment the VCN
        optionals: The IPv6 CIDR block for the VCN
  EOF
}