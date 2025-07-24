output "bastion_id" {
  value       = oci_bastion_bastion.bastion_hosts.id
  description = "Bastion service OCID"
}

output "bastion_name" {
  value       = oci_bastion_bastion.bastion_hosts.name
  description = "Bastion service name"
}

output "bastion_state" {
  value       = oci_bastion_bastion.bastion_hosts.state
  description = "Bastion service state"
}

output "session_connection_info" {
  value = {
    for k, v in oci_bastion_session.sessions : split("-", k)[0] => {
      session_id         = v.id
      connection_command = "oci bastion session create-port-forwarding --session-id ${v.id} --local-port 2222 --remote-port 22"
      type               = local.session_combinations_map[k].type
      target_name        = local.session_combinations_map[k].type == "oke" ? local.session_combinations_map[k].node.name : local.session_combinations_map[k].node.display_name
    }...
  }
  description = "Session connection information grouped by session name"
}

output "session_details" {
  value = {
    for k, v in oci_bastion_session.sessions : k => {
      session_id   = v.id
      display_name = v.display_name
      user         = local.session_combinations_map[k].session.user
      os_user      = local.session_combinations_map[k].session.os_user
      ttl_seconds  = v.session_ttl_in_seconds
      target_ip    = v.target_resource_details[0].target_resource_private_ip_address
      target_name  = local.session_combinations_map[k].type == "oke" ? local.session_combinations_map[k].node.name : local.session_combinations_map[k].node.display_name
      session_type = local.session_combinations_map[k].type
      port         = v.target_resource_details[0].target_resource_port
    }
  }
  description = "Detailed session information"
}

output "ssh_commands" {
  value = {
    for k, v in oci_bastion_session.sessions : k =>
    "ssh -o ProxyCommand=\"oci bastion session create-port-forwarding --session-id ${v.id} --local-port %p --remote-port ${v.target_resource_details[0].target_resource_port}\" ${v.target_resource_details[0].target_resource_operating_system_user_name}@localhost"
  }
  description = "Direct SSH commands for each session"
}

output "active_sessions_summary" {
  value = {
    total_sessions   = length(oci_bastion_session.sessions)
    oke_sessions     = length([for k, v in local.session_combinations_map : v if v.type == "oke"])
    compute_sessions = length([for k, v in local.session_combinations_map : v if v.type == "compute"])
    by_user = {
      for user in distinct([for k, v in local.session_combinations_map : v.session.user]) :
      user => length([for k, v in local.session_combinations_map : v if v.session.user == user])
    }
  }
  description = "Summary of active sessions"
}