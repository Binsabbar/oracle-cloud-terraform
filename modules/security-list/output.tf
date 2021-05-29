output "ids" {
  value = { for key, sec_list in oci_core_security_list.security_list : key => sec_list.id }
}