variable "mysql_dbs" {
  type = map(object({
    hostname_label      = string
    compartment_id      = string
    subnet_id           = string
    availability_domain = string
    admin_password      = string
    enable_backup       = bool

    optionals = any # Map of optional values. map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # admin_username = string ("admin")
    # shape_name = string ("MySQL.VM.Standard.E3.1.8GB")
    # retention_in_days = number (30)
    # backup_window_start_time = string ("00:00")
    # maintenance_window_start_time = string ("sat 22:00")
    # size_in_gb = number (100)
    # port = number (3306)
    # port_x = number (33060)
    # state = string #("ACTIVE")
    # configuration_id = string ("ocid1.mysqlconfiguration.oc1..aaaaaaaalwzc2a22xqm56fwjwfymixnulmbq3v77p5v4lcbb6qhkftxf2trq")
  }))

  description = <<EOL
  map of mysql db object configurations
    hostname_label     : name of DB used in FQDN
    compartment_id     : ocid of the compartmetn
    subnet_id          : ocid of the subnet
    availability_domain: name of the AD
    admin_password     : the password used for the admin user of the MYSQL DB
    enable_backup      : whether automatic Backup is enabled or not
    optionals          : map of extra optional configurations
      admin_username               : username to be set for the admin user
      shape_name                   : The VM Shape name
      retention_in_days            : backup retention period
      backup_window_start_time     : start time of backup
      maintenance_window_start_time: start time of DB upgrade and maintenance
      size_in_gb                   : VM size
      port                         : the listening port of DB
      port_x                       : the other listening port of DB
      state                        : is it on or off
      configuration_id             : MySQL configuration, which can be found in oracle. Create your own configuration and add ID here
  EOL
}