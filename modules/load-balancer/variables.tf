# Required
variable "compartment" {
  type = object({
    id = string
  })
}
variable "subnet_ids" { type = set(string) }
variable "name" { type = string }

variable "tcp_configurations" {
  type = map(object({
    virtual_hosts = set(string)
    port          = number
    backends = set(object({
      ip   = string,
      port = number
    }))
  }))
  default = {}
}

variable "is_private" {
  type    = bool
  default = false
}
variable "shape" {
  type    = string
  default = "100Mbps"
}
variable "security_group_ids" {
  type    = set(string)
  default = []
}
variable "idle_timeout_in_seconds" {
  type    = number
  default = 3600
}
