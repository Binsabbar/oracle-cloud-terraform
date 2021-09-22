data "oci_objectstorage_namespace" "namespace" {}


resource "oci_objectstorage_bucket" "bucket" {
  for_each = var.buckets

  namespace = data.oci_objectstorage_namespace.namespace.namespace

  compartment_id        = each.value.compartment_id
  name                  = each.key
  access_type           = each.value.is_public == true ? "ObjectReadWithoutList" : "NoPublicAccess"
  storage_tier          = each.value.storage_tier
  object_events_enabled = lookup(each.value.optionals, "object_events_enabled", false)
  versioning            = lookup(each.value.optionals, "versioning_enabled", false) ? "Enabled" : "Disabled"
}

resource "oci_objectstorage_object_lifecycle_policy" "lifecycle_policy" {
  for_each = var.buckets
  bucket    = each.key
  namespace = data.oci_objectstorage_namespace.export_namespace.namespace
  rules {
    action     = try(each.value.lifecycle_rules.action, "INFREQUENT_ACCESS")
    is_enabled = "true"
    name       = each.value.lifecycle_rules.name
    ## optional 
    object_name_filter {
      exclusion_patterns = [
      ]
      inclusion_patterns = [
      ]
      inclusion_prefixes = [
      ]
    }
    target      = "objects"
    time_amount = "each.value.lifecycle_rules.name"
    time_unit   = "DAYS"
  }
}