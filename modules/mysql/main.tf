locals {
  shapes = {
    "small" = "MySQL.VM.Standard.E3.1.8GB"
  }

  configurations_id = {
    "small" = "ocid1.mysqlconfiguration.oc1..aaaaaaaalwzc2a22xqm56fwjwfymixnulmbq3v77p5v4lcbb6qhkftxf2trq"
  }
}

resource "oci_mysql_mysql_db_system" "mysql_db_system" {
  for_each = var.mysql_dbs

  description  = each.key
  display_name = each.key

  compartment_id      = each.value.compartment_id
  subnet_id           = each.value.subnet_id
  availability_domain = each.value.availability_domain
  hostname_label      = each.value.hostname_label

  admin_password = each.value.admin_password
  admin_username = lookup(each.value.optionals, "username", "admin")
  lifecycle {
    ignore_changes = [admin_password]
  }
  shape_name       = lookup(each.value.optionals, "shape_name", local.shapes.small)
  configuration_id = lookup(each.value.optionals, "configuration_id", local.configurations_id.small)

  backup_policy {
    is_enabled        = each.value.enable_backup
    retention_in_days = lookup(each.value.optionals, "retention_in_days", 30)
    defined_tags      = lookup(each.value.optionals, "backup_window_start_time", "00:00")
    defined_tags     = { "managedby" = "terraform" }
  }

  data_storage_size_in_gb = lookup(each.value.optionals, "size_in_gb", 100)

  port   = lookup(each.value.optionals, "port", 3306)
  port_x = lookup(each.value.optionals, "port_x", 33060)
  state  = lookup(each.value.optionals, "state", "ACTIVE")

  maintenance {
    window_start_time = lookup(each.value.optionals, "maintenance_window_start_time", "sat 22:00")
  }

  freeform_tags = { "managedby" = "terraform" }
}
