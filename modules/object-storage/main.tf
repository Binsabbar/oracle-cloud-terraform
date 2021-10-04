data "oci_objectstorage_namespace" "namespace" {}

resource "oci_objectstorage_bucket" "bucket" {
  for_each = var.buckets

  namespace             = data.oci_objectstorage_namespace.namespace.namespace
  compartment_id        = each.value.compartment_id
  name                  = each.value.name
  access_type           = each.value.is_public == true ? "ObjectReadWithoutList" : "NoPublicAccess"
  storage_tier          = each.value.storage_tier
  object_events_enabled = lookup(each.value.optionals, "object_events_enabled", false)
  versioning            = lookup(each.value.optionals, "versioning_enabled", false) ? "Enabled" : "Disabled"
}

resource "oci_objectstorage_object_lifecycle_policy" "lifecycle_policy" {
  for_each  = var.buckets
  bucket    = each.value.name
  namespace = data.oci_objectstorage_namespace.namespace.namespace

  dynamic "rules" {
    for_each = each.value.lifecycle_rules
    content {
      action     = rules.value.action
      is_enabled = rules.value.enabled
      name       = rules.value.name
      object_name_filter {
        exclusion_patterns = rules.value.exclusion_patterns
        inclusion_patterns = rules.value.inclusion_patterns
        inclusion_prefixes = rules.value.inclusion_prefixes
      }
      target      = rules.value.target
      time_amount = rules.value.time
      time_unit   = rules.value.time_unit
    }
  }
}
