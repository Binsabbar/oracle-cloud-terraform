data "oci_objectstorage_namespace" "namespace" {}

resource "oci_objectstorage_bucket" "bucket" {
  for_each = var.buckets

  namespace             = data.oci_objectstorage_namespace.namespace.namespace
  compartment_id        = each.value.compartment_id
  name                  = each.value.name
  defined_tags          = lookup(each.value, "defined_tags", null)
  access_type           = each.value.is_public == true ? "ObjectReadWithoutList" : "NoPublicAccess"
  storage_tier          = each.value.storage_tier
  object_events_enabled = try(each.value.optionals.object_events_enabled, false)
  versioning            = try(each.value.optionals.versioning, "Disabled")
}

resource "oci_objectstorage_object_lifecycle_policy" "lifecycle_policy" {
  for_each  = var.buckets
  bucket    = oci_objectstorage_bucket.bucket[each.key].name
  namespace = data.oci_objectstorage_namespace.namespace.namespace

  dynamic "rules" {
    for_each = { for k, v in each.value.lifecycle_rules : k => v if v.target != "multipart-uploads" }
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

  dynamic "rules" {
    for_each = { for k, v in each.value.lifecycle_rules : k => v if v.target == "multipart-uploads" }
    content {
      action      = rules.value.action
      is_enabled  = rules.value.enabled
      name        = rules.value.name
      target      = rules.value.target
      time_amount = rules.value.time
      time_unit   = rules.value.time_unit
    }
  }
}
resource "oci_objectstorage_replication_policy" "bucket_replication" {
  for_each = {
    for k, v in var.buckets : k => v if try(v.optionals.replication_policy.source_region_name, null) == var.region
  }
  name                    = each.value.name
  bucket                  = oci_objectstorage_bucket.bucket[each.key].name
  namespace               = data.oci_objectstorage_namespace.namespace.namespace
  destination_bucket_name = coalesce(try(each.value.optionals.replication_policy.destination_bucket_name, null), oci_objectstorage_bucket.bucket[each.key].name)
  destination_region_name = each.value.optionals.replication_policy.destination_region_name
}
