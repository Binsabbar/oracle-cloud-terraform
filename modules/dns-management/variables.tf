variable "zone_type" {
  type        = string
  default     = "PRIMARY"
  description = "The type of the zone."
}

variable "scope" {
  type        = string
  default     = "PRIVATE"
  description = "Specifies to operate only on resources that have a matching DNS scope. This value will be null for zones in the global DNS and PRIVATE when creating private Rrsets."
}

variable "view_id" {
  type        = string
  description = "The OCID of the view the resource is associated with."
}

variable "compartment_id" {
  type        = string
  description = "The OCID of the compartment the resource belongs to."
}

variable "zones" {
  type = map(object({
    records = map(object({
      domain_name = string
      rdata       = string
      rtype       = optional(string, "A") # Optional with default value
      ttl         = optional(number, 300) # Optional with default value
    }))
  }))
  description = <<EOF
    Map of DNS zones and their records
    zone_name - First map key for DNS zones
    domain_name - The target fully-qualified domain name (FQDN) within the target zone.
    rtype - The type of the target RRSet within the target zone.
    rdata - The record's data, as whitespace-delimited tokens in type-specific presentation format. All RDATA is normalized and the returned presentation of your RDATA may differ from its initial input. For more information about RDATA, see Supported DNS Resource Record Types
    ttl - The Time To Live for the record, in seconds.    
  EOF
}