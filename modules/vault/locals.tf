locals {
 
  flattened_keys = flatten([
    for vault_ref, vault in var.vaults: [
      for key_ref, key in vault.keys : merge(key, { vault_ref = vault_ref, key_ref = key_ref })
    ]
  ])
  
  flattened_keys_rotations = flatten([
    for vault_ref, vault in var.vaults: [
      for key_ref, key in vault.keys : [
        for version in key.versions: {version = version, vault_ref = vault_ref, key_ref = key_ref }
      ]
    ]
  ])
  
  flattened_keys_for_file_restored_vault = flatten([
    for vault_ref, vault in var.file_restored_vaults: [
      for key_ref, key in vault.keys : merge(key, { vault_ref = vault_ref, key_ref = key_ref })
    ]
  ])

  flattened_keys_rotations_for_file_restored_vault = flatten([
    for vault_ref, vault in var.file_restored_vaults: [
      for key_ref, key in vault.keys : [
        for version in key.versions: {version = version, vault_ref = vault_ref, key_ref = key_ref }
      ]
    ]
  ])
  
  flattened_keys_for_object_restored_vault = flatten([
    for vault_ref, vault in var.object_store_restored_vaults: [
      for key_ref, key in vault.keys : merge(key, { vault_ref = vault_ref, key_ref = key_ref })
    ]
  ])

  flattened_keys_rotations_for_object_restored_vault = flatten([
    for vault_ref, vault in var.object_store_restored_vaults: [
      for key_ref, key in vault.keys : [
        for version in key.versions: {version = version, vault_ref = vault_ref, key_ref = key_ref }
      ]
    ]
  ])


}