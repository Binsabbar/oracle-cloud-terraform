data "oci_objectstorage_namespace" "namespace" {}


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