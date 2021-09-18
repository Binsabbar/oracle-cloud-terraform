#TODO v3 support replication in regions

resource "oci_kms_vault" "vault" {
  for_each = var.vaults
  
  compartment_id = each.value.compartment_id
  display_name = each.value.name
  vault_type = each.value.type
}

resource "oci_kms_key" "key" {
  for_each = { for item in local.flattened_keys: "${item.vault_ref}:${item.key_ref}" => item }
  
  compartment_id = each.value.compartment_id
  display_name = each.value.name
  desired_state = each.value.enabled ? "ENABLED" : "DISABLED"
  key_shape {
      algorithm = each.value.algorithm
      length = each.value.length
  }

  management_endpoint = oci_kms_vault.vault[each.value.vault_ref].management_endpoint
  protection_mode = each.value.mode
}

resource "oci_kms_key_version" "key_version" {
  for_each = {for item in local.flattened_keys_rotations: "${item.vault_ref}:${item.key_ref}:${item.version}" => item}

  key_id = oci_kms_key.key["${each.value.vault_ref}:${each.value.key_ref}"].id
  management_endpoint = oci_kms_vault.vault[each.value.vault_ref].management_endpoint
}


// File Restored
resource "oci_kms_vault" "file_restored_vault" {
  for_each = var.file_restored_vaults

  compartment_id = each.value.compartment_id
  display_name = each.value.name
  vault_type = each.value.type
  restore_from_file {
    content_length = each.value.file.length
    content_md5 = each.value.file.md5
    restore_vault_from_file_details = each.value.file.content
  }
}

resource "oci_kms_key" "key_for_file_restored_vault" {
  for_each = { for item in local.flattened_keys_for_file_restored_vault: "${item.vault_ref}:${item.key_ref}" => item }
  
  compartment_id = each.value.compartment_id
  display_name = each.value.name
  desired_state = each.value.enabled ? "ENABLED" : "DISABLED"
  key_shape {
      algorithm = each.value.algorithm
      length = each.value.length
  }

  management_endpoint = oci_kms_vault.vault[each.value.vault_ref].management_endpoint
  protection_mode = each.value.mode
}

resource "oci_kms_key_version" "key_version_for_file_restored_vault" {
  for_each = {for item in local.flattened_keys_rotations_for_file_restored_vault: "${item.vault_ref}:${item.key_ref}:${item.version}" => item}

  key_id = oci_kms_key.key["${each.value.vault_ref}:${each.value.key_ref}"].id
  management_endpoint = oci_kms_vault.vault[each.value.vault_ref].management_endpoint
}

// Object Store Restored
resource "oci_kms_vault" "object_store_restored_vault" {
  for_each = var.object_store_restored_vaults

  compartment_id = each.value.compartment_id
  display_name = each.value.name
  vault_type = each.value.type
  restore_from_object_store {
    bucket = each.value.oci_object_store.bucket
    destination = each.value.oci_object_store.destination
    namespace = each.value.oci_object_store.namespace
    object = each.value.oci_object_store.object
    uri = each.value.oci_object_store.uri
  }
}

resource "oci_kms_key" "key_for_object_restored_vault" {
  for_each = { for item in local.flattened_keys_for_object_restored_vault: "${item.vault_ref}:${item.key_ref}" => item }
  
  compartment_id = each.value.compartment_id
  display_name = each.value.name
  desired_state = each.value.enabled ? "ENABLED" : "DISABLED"
  key_shape {
      algorithm = each.value.algorithm
      length = each.value.length
  }

  management_endpoint = oci_kms_vault.vault[each.value.vault_ref].management_endpoint
  protection_mode = each.value.mode
}

resource "oci_kms_key_version" "key_version_for_object_restored_vault" {
  for_each = {for item in local.flattened_keys_rotations_for_object_restored_vault: "${item.vault_ref}:${item.key_ref}:${item.version}" => item}

  key_id = oci_kms_key.key["${each.value.vault_ref}:${each.value.key_ref}"].id
  management_endpoint = oci_kms_vault.vault[each.value.vault_ref].management_endpoint
}