locals {
  active_sessions = {
    for name, session in var.bastion_sessions : name => session if session.active
  }

  oke_sessions = {
    for name, session in local.active_sessions : name => session
    if session.type == "oke"
  }

  compute_sessions = {
    for name, session in local.active_sessions : name => session
    if session.type == "compute"
  }

  resolved_oke_pools = var.cluster_id != "" ? {
    for session_name, session in local.oke_sessions : session_name => {
      session = session
      pool = one([
        for np in data.oci_containerengine_node_pools.all[0].node_pools :
        np if np.name == session.pool_name
      ])
    }
  } : {}

  oke_session_node_combinations = flatten([
    for session_name, pool_data in local.resolved_oke_pools : [
      for idx, node in try(data.oci_containerengine_node_pool.resolved_pools[session_name].nodes, []) : {
        session_name = session_name
        node_index   = idx
        key          = "${session_name}-node-${idx}"
        node         = node
        session      = pool_data.session
        display_name = "${var.bastion_name}-${session_name}-${idx}"
        type         = "oke"
        target_ip    = node.private_ip
        target_id    = node.id
      }
      if(
        contains(pool_data.session.nodes, "all") ||
        contains(pool_data.session.nodes, tostring(idx)) ||
        contains(pool_data.session.nodes, node.name)
      )
    ]
    if pool_data.pool != null
  ])

  compute_session_instance_combinations = flatten([
    for session_name, session in local.compute_sessions : [
      for idx, instance in data.oci_core_instances.compute_instances[session_name].instances : {
        session_name = session_name
        node_index   = idx
        key          = "${session_name}-instance-${idx}"
        node         = instance
        session      = session
        display_name = "${var.bastion_name}-${session_name}-${instance.display_name}"
        type         = "compute"
        target_ip    = instance.private_ip
        target_id    = instance.id
      }
    ]
  ])

  all_session_combinations = concat(
    local.oke_session_node_combinations,
    local.compute_session_instance_combinations
  )

  session_combinations_map = {
    for item in local.all_session_combinations : item.key => item
  }
}