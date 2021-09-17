#TODO v3 support replication in regions

resource "oci_kms_vault" "vault" {
    #Required
    compartment_id = var.compartment_id
    display_name = var.vault_display_name
    vault_type = var.vault_vault_type

    restore_from_file {
      content_length = ""
      content_md5 = ""
      restore_vault_from_file_details = ""
    }

    restore_from_object_store {
      bucket = ""
      destination = ""
      namespace = ""
      object = ""
      uri = ""
    }
}

resource "oci_kms_key" "key" {
    #Required
    compartment_id = var.compartment_id
    display_name = var.key_display_name
    desired_state = ""
    key_shape {
        algorithm = var.key_key_shape_algorithm
        length = var.key_key_shape_length
        curve_id = oci_kms_curve.test_curve.id
    }
    management_endpoint = var.key_management_endpoint

    protection_mode = "${var.key_protection_mode}"

    restore_from_file {
      content_length = ""
      content_md5 = ""
      restore_vault_from_file_details = ""
    }

    restore_from_object_store {
      bucket = ""
      destination = ""
      namespace = ""
      object = ""
      uri = ""
    }
    restore_trigger  = ""
    time_of_deletion = ""
}

resource "oci_kms_key_version" "key_version" {
    #Required
    key_id = oci_kms_key.test_key.id
    management_endpoint = var.key_version_management_endpoint
}
w