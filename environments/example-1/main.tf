locals {
  users = {
    "user-1" = "user-1@email.com"
    "user-2" = "user-2@email.com"
    "user-3" = "user-3@email.com"
  }

  memberships = {
    "dev" = [
      local.users["user-1"],
      local.users["user-2"],
      local.users["user-3"]
    ],

    "admin" = [
      local.users["user-3"]
    ]
  }

  service_accounts = ["cicd-terraform", "webapp-a"]
}

module "main_compartments" {
  source = "github.com/Binsabbar/oracle-cloud-terraform//modules/identity?ref=v1.0"

  tenant_id = var.tenant_id
  compartments = {
    "applications" = {
      parent   = var.tenant_id
      policies = []
    }
    "common" = {
      parent   = var.tenant_id
      policies = []
    }
  }

  memberships      = local.memberships
  service_accounts = local.service_accounts

  tenancy_policies = {
    name = "admin-policy"
    policies = [
      "allow group admin to manage all-resources in tenancy"
    ]
  }
}

module "child_compartments" {
  source    = "github.com/Binsabbar/oracle-cloud-terraform//modules/identity?ref=v1.0"
  tenant_id = var.tenant_id

  compartments = {
    "ops" = {
      parent   = module.main_compartments.compartments["applications"].id
      policies = []
    }

    "developments" = {
      parent = module.main_compartments.compartments["applications"].id
      policies = [
        "allow group dev to manage all-resources in compartment developments"
      ]
    }
  }
}


module "networks" {
  source = "github.com/Binsabbar/oracle-cloud-terraform//modules/network?ref=v1.0"

  compartment_id        = module.main_compartments.compartments["applications"].id
  name                  = "developments-network"
  cidr_block            = "192.168.0.0/16"
  allowed_ingress_ports = []

  public_subnets = {
    "gateway" = {
      cidr_block        = "192.168.4.0/24"
      security_list_ids = []
      optionals         = {}
    }
  }

  private_subnets = {
    "backend" = {
      cidr_block        = "192.168.8.0/24"
      security_list_ids = []
      optionals         = {}
    }

    "storage" = {
      cidr_block        = "192.168.9.0/24"
      security_list_ids = []
      optionals         = {}
    }
  }
}

module "config" {
  source = "github.com/Binsabbar/oracle-cloud-terraform//modules/common-config?ref=v1.0"
}


module "compute" {
  source = "github.com/Binsabbar/oracle-cloud-terraform//modules/instances?ref=v1.0"
  instances = {
    "jumpbox" = {
      availability_domain_name = "XXX:ME-JEDDAH-1-AD-1"
      fault_domain_name        = "FAULT-DOMAIN-3"
      compartment_id           = module.main_compartments.compartments["applications"].id
      volume_size              = 100
      state                    = module.config.instance_config.instance_state.RUNNING
      autherized_keys          = "ssh-rsa xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      config = {
        shape           = module.config.instance_config.shapes.standard-ocp1
        image_id        = module.config.instance_config.images_ids.ubuntu_20
        subnet          = module.networks.public_subnets["gateway"]
        network_sgs_ids = []
      }
    }

    "webapp-1" = {
      availability_domain_name = "XXX:ME-JEDDAH-1-AD-1"
      fault_domain_name        = "FAULT-DOMAIN-1"
      compartment_id           = module.child_compartments.compartments["developments"].id
      volume_size              = 100
      state                    = module.config.instance_config.instance_state.RUNNING
      autherized_keys          = "ssh-rsa xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      config = {
        shape           = module.config.instance_config.shapes.standard-ocp1
        image_id        = module.config.instance_config.images_ids.ubuntu_20
        subnet          = module.networks.private_subnets["backend"]
        network_sgs_ids = []
      }
    }

    "gluster-1" = {
      availability_domain_name = "XXX:ME-JEDDAH-1-AD-1"
      fault_domain_name        = "FAULT-DOMAIN-2"
      compartment_id           = module.child_compartments.compartments["ops"].id
      volume_size              = 100
      state                    = module.config.instance_config.instance_state.RUNNING
      autherized_keys          = "ssh-rsa xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      config = {
        shape           = module.config.instance_config.shapes.standard-ocp1
        image_id        = module.config.instance_config.images_ids.ubuntu_20
        subnet          = module.networks.private_subnets["storage"]
        network_sgs_ids = []
      }
    }
  }
}