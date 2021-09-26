data "oci_objectstorage_namespace" "namespace" {}

locals {
  flattened_lifecyle_rules = [ for bucket_key, bucket_v in var.buckets: 
    for rule_k, rule_v in bucket_v.lifecycle_rules: {
      bucket_key    = bucket_key
      bucket_name   = bucket_v.name
      rule_key      = rule_k
      rule          = rule_v
    }
  ]
}

resource "oci_objectstorage_bucket" "bucket" {
  for_each = var.buckets

  namespace = data.oci_objectstorage_namespace.namespace.namespace
  compartment_id        = each.value.compartment_id
  name                  = each.value.name
  access_type           = each.value.is_public == true ? "ObjectReadWithoutList" : "NoPublicAccess"
  storage_tier          = each.value.storage_tier
  object_events_enabled = lookup(each.value.optionals, "object_events_enabled", false)
  versioning            = lookup(each.value.optionals, "versioning_enabled", false) ? "Enabled" : "Disabled"
}

resource "oci_objectstorage_object_lifecycle_policy" "lifecycle_policy" {
  for_each = { for i in local.flattened_lifecyle_rules: "${i.bucket_key}:${i.rule_key}" => i }
  bucket    = i.value.bucket_name
  namespace = data.oci_objectstorage_namespace.namespace.namespace
  
  dynamic "rules" {
    for_each = [i.rule]
    content {
      action     = rules.action
      is_enabled = rules.enabled
      name       = rules.name
      object_name_filter {
        exclusion_patterns = rules.exclusion_patterns
        inclusion_patterns = rules.inclusion_patterns
        inclusion_prefixes = rules.inclusion_prefixes
      }
      target      = rules.object
      time_amount = rules.time
      time_unit   = rules.time_unit
    }
  }
}