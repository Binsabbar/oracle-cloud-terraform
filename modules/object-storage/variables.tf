variable "buckets" {
  type = map(object({
    compartment_id = string
    name           = string
    storage_tier   = string
    is_public      = bool
    lifecycle_rules = map(object({
      name               = string
      action             = string
      enabled            = string
      exclusion_patterns = list(string)
      inclusion_patterns = list(string)
      inclusion_prefixes = list(string)
      target             = string
      time               = string
      time_unit          = string
    }))
    optionals = optional(object({
      object_events_enabled = optional(bool)
      versioning_enabled    = optional(string)
      replication_policy = optional(object({
        destination_region_name = string
        source_region_name      = string
        destination_bucket_name = optional(string)
      }))
    }))
  }))

  description = <<EOL
  map of bucket configrations
    name          : the name of the bucket
    compartment_id: ocid of the compartment
    storage_tier  : the tier of the storage (Standard, etc)
    is_public     : to make it accessiable to the public or not
    optionals     : map of optional configuration for the bucket
      # object_events_enabled: emits events for objects actions
      # versioning_enabled   : enable version of objects
  EOL
}

variable "region" { type = string }
