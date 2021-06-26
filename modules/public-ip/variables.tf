variable "compartment_id" {
  type        = string
  description = "oci of the compartment"
}

variable "ips" {
  type        = list(string)
  description = "This is a list of IPs NAMES (public IPs are created randomly by oci)"
}
