output "drg" {
  value = oci_core_drg.drg
}

output "attachments" {
  value = oci_core_drg_attachment.drg_attachments
}

output "remote_peering_connections" {
  value = oci_core_remote_peering_connection.remote_peering_connection
}
