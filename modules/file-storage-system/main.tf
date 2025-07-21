locals {
  flattened_exports = flatten([
    for file_system_name, config in var.fss : [
      for export_name, export in config.exports :
      {
        fss     = file_system_name
        name    = export_name
        path    = export.path
        options = export.options
      }
    ]
  ])
}

resource "oci_file_storage_mount_target" "mount_target" {
  display_name        = var.mount_target.hostname_label
  availability_domain = var.mount_target.availability_domain
  compartment_id      = var.mount_target.compartment_id
  subnet_id           = var.mount_target.subnet_id
  hostname_label      = var.mount_target.hostname_label
  nsg_ids             = var.mount_target.nsg_ids

  defined_tags = { "managedBy" = "Terraform" }
}

resource "oci_file_storage_export_set" "export_set" {
  mount_target_id = oci_file_storage_mount_target.mount_target.id
}

resource "oci_file_storage_file_system" "file_system" {
  for_each = var.fss

  display_name        = each.key
  availability_domain = each.value.availability_domain
  compartment_id      = each.value.compartment_id

  defined_tags = { "managedBy" = "Terraform" }
}

resource "oci_file_storage_export" "export" {
  for_each       = { for e in local.flattened_exports : "${e.fss}:${e.name}:${e.path}" => e }
  export_set_id  = oci_file_storage_export_set.export_set.id
  file_system_id = oci_file_storage_file_system.file_system[each.value.fss].id
  path           = each.value.path

  dynamic "export_options" {
    for_each = each.value.options
    content {
      source                         = export_options.value.source
      access                         = export_options.value.access
      require_privileged_source_port = lookup(export_options.value.optionals, "require_privileged_source_port", "true")
      identity_squash                = lookup(export_options.value.optionals, "identity_squash", "ROOT")
      anonymous_gid                  = lookup(export_options.value.optionals, "anonymous_gid", "65534")
      anonymous_uid                  = lookup(export_options.value.optionals, "anonymous_uid", "65534")
    }
  }


}
