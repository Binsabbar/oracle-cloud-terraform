data "oci_containerengine_cluster_kube_config" "cluster_kube_config" {
  #Required
  cluster_id = oci_containerengine_cluster.cluster.id
}

output "kube_config" {
  value = data.oci_containerengine_cluster_kube_config.cluster_kube_config.content
}

output "nodes_ips" {
  value = flatten([
    for node_pool_name, node_pool in oci_containerengine_node_pool.node_pool : [
      for node in node_pool.nodes : [node.private_ip]
    ]
  ])
}
