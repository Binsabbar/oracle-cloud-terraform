resource "oci_core_public_ip" "ip" {
  for_each = toset(var.untracked_ips)

  compartment_id = var.compartment_id
  lifetime       = "RESERVED" # if it gets disconnected from insistence it will destroy itself
  display_name   = each.key

  lifecycle {
    # it is going to be assigned after creation so lets ignore its change
    ignore_changes = [private_ip_id, defined_tags]
  }
}


resource "oci_core_public_ip" "tracked_ip" {
  for_each = var.tracked_ips

  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = each.value.name
  private_ip_id  = each.value.private_ip_id
}
