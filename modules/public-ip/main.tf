resource "oci_core_public_ip" "ip" {
  for_each = toset(var.ips)

  compartment_id = var.compartment_id
  lifetime       = "RESERVED" # if it gets disconnected from insistence it will destroy itself
  display_name   = "${each.key}-public-ip"

  lifecycle {
    # it is going to be assigned after creation so lets ignore its change
    ignore_changes = [private_ip_id, defined_tags]
  }
}
