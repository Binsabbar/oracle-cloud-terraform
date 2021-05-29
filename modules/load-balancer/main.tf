resource "oci_load_balancer_load_balancer" "load_balancer" {
  compartment_id             = var.compartment.id
  display_name               = var.name
  subnet_ids                 = var.subnet_ids
  shape                      = var.shape
  is_private                 = var.is_private
  network_security_group_ids = var.security_group_ids
}

// create backend_set
// for each backend_set in tcp_config
// make backend_set
resource "oci_load_balancer_backend_set" "tcp_backend_set" {
  for_each = var.tcp_configurations

  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  name             = each.key
  policy           = "LEAST_CONNECTIONS"

  health_checker {
    protocol          = "TCP"
    interval_ms       = "60000"
    retries           = 3
    return_code       = 200
    timeout_in_millis = 3000
    url_path          = "/health"
  }
}

// create backends
// for each backend_set in tcp_config
// for each backed in backend_set.backends
// create backend in the backendset
resource "oci_load_balancer_backend" "tcp_backend" {
  for_each = { for item in local.flattened_tcp_server_backends : "${item.backend_set}.${item.ip}:${item.port}" => item }

  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  backendset_name  = oci_load_balancer_backend_set.tcp_backend_set[each.value.backend_set].name
  ip_address       = each.value.ip
  port             = each.value.port
}

// create virtual hosts
// for each backend_set in tcp_config
// for each host in backend_set.virtual_hosts
// create hostname
resource "oci_load_balancer_hostname" "tcp_virtual_hostnames" {
  for_each = { for v in local.flattened_tcp_virtual_hosts : "${v.backend_set}:${v.virtual_host}" => v.virtual_host }

  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  hostname         = each.value
  name             = each.key
  lifecycle {
    create_before_destroy = true
  }
}

// create a listener
// for each backend_set in tcp_config
// create listener
resource "oci_load_balancer_listener" "tcp_listener" {
  for_each = var.tcp_configurations

  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer.id
  default_backend_set_name = oci_load_balancer_backend_set.tcp_backend_set[each.key].name
  # hostname_names           = local.oci_load_balancer_hostname_names[each.key]
  name     = each.key
  port     = each.value.port
  protocol = "TCP"

  connection_configuration {
    idle_timeout_in_seconds = var.idle_timeout_in_seconds
  }
}
