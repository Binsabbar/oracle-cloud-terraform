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
    name  = string
    rtype = string
    records = map(object({
      domain = string
      rdata  = string
      rtype  = string
      ttl    = number
    }))
  }))
  description = <<EOF
    name - (Required) The target fully-qualified domain name (FQDN) within the target zone.
    rtype - (Required) The type of the target RRSet within the target zone.
    records - (Optional) (Updatable) NOTE Omitting items at time of create, will delete any existing records in the RRSet
        domain - (Required) The fully qualified domain name where the record can be located.
        rdata - (Required) (Updatable) The record's data, as whitespace-delimited tokens in type-specific presentation format. All RDATA is normalized and the returned presentation of your RDATA may differ from its initial input. For more information about RDATA, see Supported DNS Resource Record Types
        rtype - (Required) The canonical name for the record's type, such as A or CNAME. For more information, see Resource Record (RR) TYPEs.
        ttl - (Required) (Updatable) The Time To Live for the record, in seconds.    
  EOF

}

