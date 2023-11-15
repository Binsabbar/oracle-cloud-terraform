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
    ports     = object({ min : number, max : number })
    ips       = set(string)
  })))

  default = {}
  validation {
    condition = alltrue([
      for group_name, group in var.network_security_groups :
      alltrue([
        for rule_name, rule in group : rule.direction == "INGRESS" || rule.direction == "EGRESS"
      ])
    ])
    error_message = <<EOF
    The value of direction must be one of the following:
    - "INGRESS"
    - "EGRESS"
    EOF
  }
  description = <<EOL
    map of network security groups, where the key is used as name of the group, and value is a rule configuration
    Rule Configuration
    direction: INGRESS or EGRESS
    protocol : tcp or udp
    ports    : port object that contain the port ranege. Set both min and max to the same value if no range is needed
        min: lower port bound 
        max: upper port bound
    ips      : list of IP addresses for the rule
  EOL
}