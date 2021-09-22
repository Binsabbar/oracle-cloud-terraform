variable "buckets" {
  type = map(object({
    compartment_id = string
    storage_tier   = string
    is_public      = bool
    lifecycle_rules      = map(object({
      name = string
      action = string
      enabled = string
      exclusion_patterns = tuple
      inclusion_patterns = tuple
      inclusion_prefixes  = tuple
      target = string
      time = string
      time_unit = string
    }))
    optionals      = any # map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # object_events_enabled = bool - false
    # versioning_enabled    = bool - false
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