
variable "vcn_id" { type = string }
variable "compartment_id" { type = string }
variable "security_lists" {
  type = map(object({
    egress_rules = map(object({
      protocol    = number
      ports       = object({ min : number, max : number })
      destination = string
      optionals   = map(any)
      # The followings are the keys for the optionals with defaults in brackets
      # type = string(CIDR)
    }))
    ingress_rules = map(object({
      protocol  = number
      ports     = object({ min : number, max : number })
      source    = string
      optionals = map(any)
      # The followings are the keys for the optionals with defaults in brackets
      # type = string(CIDR)
    }))
  }))

  description = <<EOL
  map of security list objects, where key is used as security list name. Each list must contain the following
    egress_rules: map of rule object. Leave empty `{}` if no rules to be created
      protocol   : protocol to be used (must be protocol number)
      ports      : port object that contain the port rane. Set both min and max to the same value if no range is needed
        min: lower port bound 
        max: upper port bound
      destination: IP address that this rule applies to for the destination of network packet
      optionals: not used
    ingress_rules: map of rule object. Leave empty `{}` if no rules to be created
      protocol   : protocol to be used (must be protocol number)
      ports      : port object that contain the port rane. Set both min and max to the same value if no range is needed
        min: lower port bound 
        max: upper port bound
      source: IP address that this rule applies to for the source of network packet
      optionals: not used
  EOL
}
