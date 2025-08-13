locals {
  autoscale_nodes = { for k, v in var.node_pools :
    k => v if v.size == 0
  }
  static_nodes = { for k, v in var.node_pools :
    k => v if v.size != 0
  }
}

resource "oci_containerengine_cluster" "cluster" {
  compartment_id     = var.compartment_id
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  kubernetes_version = var.cluster_k8s_version

  endpoint_config {
    is_public_ip_enabled = var.endpoint_config.is_public_ip_enabled
    nsg_ids              = var.endpoint_config.nsg_ids
    subnet_id            = var.endpoint_config.subnet_id
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = var.enable_kubernetes_dashboard
      is_tiller_enabled               = true
    }
    service_lb_subnet_ids = var.lb_subnet_ids
    ip_families = var.ip_families
    dynamic "kubernetes_network_config" {
      for_each = var.kubernetes_network_config
      content {
        pods_cidr     = kubernetes_network_config.pods_cidr
        services_cidr = kubernetes_network_config.services_cidr
      }
    }
  }

  lifecycle {
    ignore_changes = [
      options[0].service_lb_subnet_ids
    ]
    prevent_destroy = true
  }
}

resource "oci_containerengine_node_pool" "node_pool" {
  for_each = local.static_nodes

  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = each.value.compartment_id
  kubernetes_version = each.value.k8s_version
  name               = "${each.key}-node-pool"
  node_shape         = each.value.shape
  ssh_public_key     = each.value.ssh_public_key
  node_metadata      = each.value.node_metadata

  dynamic "initial_node_labels" {
    for_each = each.value.labels
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }
  node_config_details {
    size         = each.value.size
    defined_tags = each.value.defined_tags
    placement_configs {
      availability_domain = each.value.availability_domain
      subnet_id           = each.value.subnet_id
    }
  }

  node_source_details {
    image_id                = each.value.image_id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = each.value.volume_size_in_gbs
  }

  dynamic "node_shape_config" {
    for_each = length(each.value.flex_shape_config) == 2 ? [1] : []
    content {
      memory_in_gbs = each.value.flex_shape_config.memory_in_gbs
      ocpus         = each.value.flex_shape_config.ocpus
    }
  }
}

resource "oci_containerengine_node_pool" "node_pool_ignored_size" {
  for_each = local.autoscale_nodes

  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = each.value.compartment_id
  kubernetes_version = each.value.k8s_version
  name               = "${each.key}-node-pool"
  node_shape         = each.value.shape
  ssh_public_key     = each.value.ssh_public_key
  node_metadata      = each.value.node_metadata

  dynamic "initial_node_labels" {
    for_each = each.value.labels
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }
  node_config_details {
    size         = each.value.size
    defined_tags = each.value.defined_tags
    placement_configs {
      availability_domain = each.value.availability_domain
      subnet_id           = each.value.subnet_id
    }
  }

  node_source_details {
    image_id                = each.value.image_id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = each.value.volume_size_in_gbs
  }

  dynamic "node_shape_config" {
    for_each = length(each.value.flex_shape_config) == 2 ? [1] : []
    content {
      memory_in_gbs = each.value.flex_shape_config.memory_in_gbs
      ocpus         = each.value.flex_shape_config.ocpus
    }
  }

  lifecycle {
    ignore_changes = [
      node_config_details[0].size
    ]
  }
}
