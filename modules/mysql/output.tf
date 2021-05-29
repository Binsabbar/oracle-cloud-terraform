output "mysql_db_systems" {
  value = {
    for k, v in oci_mysql_mysql_db_system.mysql_db_system :
    k => { endpoints = v.endpoints }
  }
}