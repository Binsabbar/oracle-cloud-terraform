data "oci_containerengine_node_pools" "all" {
  count          = var.cluster_id != "" ? 1 : 0
  compartment_id = var.compartment_id
  cluster_id     = var.cluster_id
}

data "oci_containerengine_node_pool" "resolved_pools" {
  for_each     = local.oke_sessions
  node_pool_id = local.resolved_oke_pools[each.key].pool.id
}

data "oci_core_instances" "compute_instances" {
  for_each       = local.compute_sessions
  compartment_id = each.value.compartment_id != "" ? each.value.compartment_id : var.compartment_id

  filter {
    name   = "display_name"
    values = each.value.instance_names
  }

  filter {
    name   = "state"
    values = ["RUNNING"]
  }
}
