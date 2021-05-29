output "instance_config" {
  value = {
    instance_state = {
      RUNNING = "RUNNING"
      STOPPED = "STOPPED"
    }

    images_ids = {
      ubuntu_20                   = "ocid1.image.oc1.me-jeddah-1.aaaaaaaay5jjjjj5bv2hh5553oi2ljo7nc36dxhx75sarcecs5ozlu374lja"
      oracle_linux_7_8_2020_09_23 = "ocid1.image.oc1.me-jeddah-1.aaaaaaaaaqsxujxurzktxkwx4umh3k7vawylcpi6qibvduvx4cuf5vctajea"
      oracle_linux_7_9_2021_01_12 = "ocid1.image.oc1.me-jeddah-1.aaaaaaaawnlta4ua2sytgjsdd7asdb4naqbgpbiycpcmicdpi3jufh2qajuq"
    }

    shapes = {
      micro          = "VM.Standard.E2.1.Micro"
      standard-ocp1  = "VM.Standard2.1"
      standard-ocp2  = "VM.Standard2.2"
      standard-ocp4  = "VM.Standard2.4"
      standard-ocp8  = "VM.Standard2.8"
      standard-ocp16 = "VM.Standard2.16"
      standard-ocp24 = "VM.Standard2.24"
    }
  }
}
