# MySQL
Using this module, you can create multiple MySQL DB systems. Have a look at `variables.tf` to see the accepted input. The module allows you to configure backup and retention.

## Example:
Creating two DB systems
```h
module "mysql" {
  source = "../../modules/mysql"

  mysql_dbs = {
    "product-a" = {
      hostname_label      = "mysql-db-1"
      compartment_id      = "ocixxxxxx.xxxxxx.xxxxx"
      subnet_id           = "ocixxxxxx.xxxxxx.xxxxx"
      availability_domain = "AD-1-JED"
      admin_password      = "xxxxxxxxxxxxxxx"
      enable_backup       = true
      optionals           = {
        admin_username = "my-db-admin-user"
        shape_name = "MySQL.VM.Standard.E3.1.8GB"
        retention_in_days = 35
        backup_window_start_time = "00:00"
        maintenance_window_start_time = "sat 22:00"
        size_in_gb = 500
        port = 3303
        port_x = 33022
        state = "ACTIVE"
        configuration_id = "ocid1.mysqlconfiguration.oc1..aaaaaaaalwzc2a22xqm56fwjwfymixnulmbq3v77p5v4lcbb6qhkftxf2trq"
      }
    }
  
    "product-b" = {
      hostname_label      = "mysql-db-2"
      compartment_id      = "ocixxxxxx.xxxxxx.xxxxx"
      subnet_id           = "ocixxxxxx.xxxxxx.xxxxx"
      availability_domain = "AD-1-JED"
      admin_password      = "xxxxxxxxxxxxxxx"
      enable_backup       = false
      optionals = {}
    }
  }
}

```