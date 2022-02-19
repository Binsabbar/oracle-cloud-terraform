# KMS
The module enables you to mange encryption keys that can be used in block volumes, or other services. Using this module you can:
1. Create vault.
2. Create Master Key
3. Rotate keys (by updating `var.vaults[].keys[].versions`)

## Key Rotations
Rotating keys can occure by adding a version number to the set `var.vaults[].keys[].versions`. One clean way of doing this,
is by using Terraform function `range`. For example to create 2 version of a key `range(1, 3)`. This yields `[1, 2]`. Alternatively set the value manually `[1,2]`.

## Resotration from existing Vault
This module support `vault` restorations only. `keys` restorations alone are not supported. In other words, you can't restore an single `key`, but you need to restore the whole `vault` to a new `vault`.

## Limitations
* There is limitations with importing existing keys form file or from S3 buckets. Imported keys will NOT be managed by Terraform. You need to import the keys manually to Terraform state.
  * If keys imported from files: import keys to `module.NAME.oci_kms_key.key_for_file_restored_vault["KEY_NAME]` state and ensure key is added to module input `var.file_restored_vaults.keys[]`
  * If keys imported from Object Storage: import keys to `module.NAME.oci_kms_key.key_for_object_restored_vault["KEY_NAME]` state and ensure key is added to module input `var.object_store_restored_vaults.keys[]`.

## Examples

Simple use
```h
module "kms" {
  source = PATH_TO_MODULE

  vaults = {
    "my-kms" = {
      name           = "KMS for encryption!"
      compartment_id = "oci.xxxxxxxxxxx"
      type           = module.common_config.vault_constants.vault_types.default
      keys = {
        "master-key" = {
          name           = "master-key"
          compartment_id = "oci.xxxxxxxxxxx"
          length         = module.common_config.vault_constants.key_shapes.aes.length.32
          algorithm      = module.common_config.vault_constants.key_shapes.aes.name
          enabled        = true
          mode           = module.common_config.vault_constants.protect_mode.hardware
          versions       = []
        }
      }
    }
  }
}
```

Full example with restoration
```h
module "kms" {
  source = PATH_TO_MODULE

  vaults = {
    "my-kms" = {
      name           = "KMS for encryption!"
      compartment_id = "oci.xxxxxxxxxxx"
      type           = module.common_config.vault_constants.vault_types.default
      keys = {
        "master-key" = {
          name           = "master-key"
          compartment_id = "oci.xxxxxxxxxxx"
          length         = module.common_config.vault_constants.key_shapes.aes.length.32
          algorithm      = module.common_config.vault_constants.key_shapes.aes.name
          enabled        = true
          mode           = module.common_config.vault_constants.protect_mode.hardware
          versions       = []
        }
      }
    }
  }

  object_store_restored_vaults = {
    name           = "KMS restored from OS"
    compartment_id = "oci.xxxxxxxxxxx"
    type           = module.common_config.vault_constants.vault_types.default
    oci_object_store = {
      bucket      = "kms-backup"
      destination = "PRE_AUTHENTICATED_REQUEST_URI"
      namespace   = "XYZ"
      object      = "vault-backup-1"
      uri         = "https://myobject-storage-url"
    }
    keys = {}
  }

  file_restored_vaults = {
    name           = "KMS restored from file"
    compartment_id = "oci.xxxxxxxxxxx"
    type           = module.common_config.vault_constants.vault_types.default
    file = {
      length  = length(file("${path.module}/mybackupvault"))
      md5     = md5(file("${path.module}/mybackupvault"))
      content = file("${path.module}/mybackupvault")
    }
    keys = {}
  }
}
```