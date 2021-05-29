output "mount_target" {
  value = {
    ip = oci_file_storage_mount_target.mount_target.ip_address
  }
}