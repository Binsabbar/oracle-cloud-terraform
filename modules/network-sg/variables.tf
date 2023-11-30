variable "vcn_id" {
  type        = string
  description = "the ocid of virtual coud network"
}

variable "compartment_id" {
  type        = string
  description = "the ocid of compartment"
}

variable "network_security_groups" {
  type = map(map(object({
    direction = string
    protocol  = string
    port      = number
    ips       = set(string)
    nsg_id    = string
    use_nsg   = bool
  })))

  default = {}

  description = <<EOL
    map of network security groups, where the key is used as name of the group, and value is a rule configuration
    Rule Configuration
    direction: INGRESS or EGRESS
    protocol : tcp or udp
    port     : the port for this rule
    ips      : list of IP addresses for the rule
  EOL
}