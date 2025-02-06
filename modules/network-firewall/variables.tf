variable "go_binary_os_arch" {
  type = string
  description = "the arch of the os"
  validation {
    condition = var.go_binary_os_arch == "linux_amd64" || var.go_binary_os_arch == "linux_arm64" || var.go_binary_os_arch == "darwin_amd64" || var.go_binary_os_arch == "darwin_arm64"
    error_message = "only linux_amd64, linux_arm64, darwin_arm64 and darwin_amd64 are supported"
  }
}

variable "path_to_oci_config" {
  type = string
  default = ""
}

variable "firewalls" {
  type = map(object({
    name                = string
    compartment_id      = string
    availability_domain = optional(string, "")
    policy_name         = string
    networking = object({
      subnet_id          = string
      ipv4address        = string
      ipv6address        = optional(string, "")
      security_group_ids = set(string)
    })
  }))
}


variable "policies" {
  type = map(object({
    name           = string
    compartment_id = string
    address_lists  = optional(map(list(string)), {})
    url_lists      = optional(map(list(string)), {})
    services = optional(object({
      definitions = map(object({
        port_ranges = list(object({
          min_port = number,
          max_port = number
        })),
      type = string }))
      lists = map(list(string))
    }), null)
    applications = optional(object({
      definitions = map(object({
        protocol = string,
        type     = number
      }))
      lists = map(list(string))
    }), null)
    order_rules = optional(bool, false)
    rules = optional(list(object({
      name                  = string
      action                = string
      inspection            = optional(string, "")
      source_addresses      = optional(set(string), [])
      destination_addresses = optional(set(string), [])
      application_lists     = optional(set(string), [])
      service_lists         = optional(set(string), [])
      url_lists             = optional(set(string), [])
    })), [])
  }))

  validation {
    condition = alltrue(flatten(
      [for _, p in var.policies : [
        for _, r in p.rules : [
          contains(["INTRUSION_DETECTION", "INTRUSION_PREVENTION"], r.inspection)
        ] if r.action == "INSPECT"
      ]]
    ))
    error_message = "When Action is INSPECT you must set inspection to one of the following [\"INTRUSION_DETECTION\", \"INTRUSION_PREVENTION\"]"
  }
}
