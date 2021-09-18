output "vaults" {
  value = {
    created_vaults = { for vault_ref, vault in var.vaults: 
      vault_ref => {
        id = oci_kms_vault.vault[vault_ref].id
        crypto_endpoint = oci_kms_vault.vault[vault_ref].crypto_endpoint
        management_endpoint =  oci_kms_vault.vault[vault_ref].management_endpoint
        keys = {for key_ref, key in vault.keys: key_ref => {
          id = oci_kms_key.key["${vault_ref}:${key_ref}"].id
          vault_id = oci_kms_vault.vault[vault_ref].id
          versions = {for version in key.versions: 
            version => {
            id = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].key_version_id
            key_id = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].key_id
            is_primary = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].is_primary
            }
          }
        }}
      }
    }

    file_restored_vaults = { for vault_ref, vault in var.file_restored_vaults: 
      vault_ref => {
        id = oci_kms_vault.vault[vault_ref].id
        crypto_endpoint = oci_kms_vault.vault[vault_ref].crypto_endpoint
        management_endpoint =  oci_kms_vault.vault[vault_ref].management_endpoint
        keys = {for key_ref, key in vault.keys: key_ref => {
          id = oci_kms_key.key["${vault_ref}:${key_ref}"].id
          vault_id = oci_kms_vault.vault[vault_ref].id
          versions = {for version in key.versions: 
            version => {
            id = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].key_version_id
            key_id = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].key_id
            is_primary = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].is_primary
            }
          }
        }}
      }
    }

    object_restored_vaults = { for vault_ref, vault in var.object_store_restored_vaults: 
      vault_ref => {
        id = oci_kms_vault.vault[vault_ref].id
        crypto_endpoint = oci_kms_vault.vault[vault_ref].crypto_endpoint
        management_endpoint =  oci_kms_vault.vault[vault_ref].management_endpoint
        keys = {for key_ref, key in vault.keys: key_ref => {
          id = oci_kms_key.key["${vault_ref}:${key_ref}"].id
          vault_id = oci_kms_vault.vault[vault_ref].id
          versions = {for version in key.versions: 
            version => {
            id = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].key_version_id
            key_id = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].key_id
            is_primary = oci_kms_key_version.key_version["${vault_ref}:${key_ref}:${version}"].is_primary
            }
          }
        }}
      }
    }
  }
}
