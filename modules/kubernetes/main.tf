resource "oci_containerengine_cluster" "cluster" {
  compartment_id     = var.compartment_id
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  kubernetes_version = var.cluster_k8s_version

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = var.enable_kubernetes_dashboard
      is_tiller_enabled               = true
    }
    service_lb_subnet_ids = var.lb_subnet_ids
  }
}

resource "oci_containerengine_node_pool" "node_pool" {
  for_each = var.node_pools

  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = each.value.compartment_id
  kubernetes_version = each.value.node_pool_k8s_version
  name               = "${each.key}-node-pool"
  node_shape         = each.value.shape
  ssh_public_key     = each.value.ssh_public_key
  dynamic "initial_node_labels" {
    for_each = each.value.labels
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  node_config_details {
    size = each.value.size
    placement_configs {
      availability_domain = each.value.availability_domain
      subnet_id           = each.value.subnet_id
    }
  }

  node_source_details {
    image_id    = each.value.image_id
    source_type = "IMAGE"
  }
}
