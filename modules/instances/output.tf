output "instances" {
  value = {
    for k, instance in oci_core_instance.instances : k => {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}