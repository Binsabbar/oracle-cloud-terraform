locals {
  // map the ..........
  /*
  from:
    ...
  To:
    ...
  */
  flattened_backend_sets = flatten([
    for load_balancer_key, load_balancer in var.nlbs : [
      for listener_key, listener in load_balancer.listeners : {
        name               = "${load_balancer_key}-${listener_key}-backendset:${listener.backend_set.backend_port}"
        load_balancer_name = load_balancer_key
        listener_name      = listener_key
        backend_port       = listener.backend_set.backend_port
        health_checker     = listener.backend_set.health_checker
      }
    ]
  ])

  flattened_backends = flatten([
    for load_balancer_key, load_balancer in var.nlbs : [
      for listener_key, listener in load_balancer.listeners : [
        for ip in listener.backend_set.backend_ips :
        {
          name               = "${load_balancer_key}-${listener_key}-backendset:${listener.backend_set.backend_port}:${ip}"
          backendset_name    = "${load_balancer_key}-${listener_key}-backendset:${listener.backend_set.backend_port}"
          load_balancer_name = load_balancer_key
          listener_name      = listener_key
          backend_port       = listener.backend_set.backend_port
          ip                 = ip
        }
      ]
    ]
  ])

  flattened_listeners = flatten([
    for load_balancer_key, load_balancer in var.nlbs : [
      for listener_key, listener in load_balancer.listeners : {
        name               = "${load_balancer_key}-${listener_key}"
        backendset_name    = "${load_balancer_key}-${listener_key}-backendset:${listener.backend_set.backend_port}"
        load_balancer_name = load_balancer_key
        port               = listener.port
        protocol           = listener.protocol
      }
    ]
  ])
}

resource "oci_network_load_balancer_network_load_balancer" "nlb" {
  for_each = var.nlbs

  compartment_id                 = each.value.compartment_id
  display_name                   = each.key
  subnet_id                      = each.value.subnet_id
  is_private                     = each.value.is_private
  network_security_group_ids     = each.value.nsg_ids
  is_preserve_source_destination = null # if you set true it BRICKS LOADBALANCER!!!!!!!

  dynamic "reserved_ips" {
    for_each = each.value.reserved_ip_id != "" ? [each.value.reserved_ip_id] : []
    content {
      id = reserved_ips.value
    }
  }
}

# Backend Set
resource "oci_network_load_balancer_backend_set" "oci_backend_set" {

  for_each = { for backend_set in local.flattened_backend_sets : backend_set.name => backend_set }

  name                     = each.key
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb[each.value.load_balancer_name].id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  # documentation says this ^ don't work with ip_address in backend but it actually works

  health_checker {
    protocol           = each.value.health_checker.protocol
    interval_in_millis = each.value.health_checker.interval_in_millis
    port               = each.value.backend_port
    retries            = each.value.health_checker.retries
    timeout_in_millis  = each.value.health_checker.timeout_in_millis
  }
}

# Backend
resource "oci_network_load_balancer_backend" "oci_backend" {
  for_each = { for backend in local.flattened_backends : backend.name => backend }

  name                     = each.key
  backend_set_name         = oci_network_load_balancer_backend_set.oci_backend_set[each.value.backendset_name].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb[each.value.load_balancer_name].id
  port                     = each.value.backend_port
  ip_address               = each.value.ip
  # id_target says it take privateip-ocid and instance-ocid but it DOESN'T work with instance-ocid, it just fails
}

# Listener

resource "oci_network_load_balancer_listener" "oci_listener" {
  for_each = { for listener in local.flattened_listeners : listener.name => listener }

  name                     = each.key
  default_backend_set_name = oci_network_load_balancer_backend_set.oci_backend_set[each.value.backendset_name].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb[each.value.load_balancer_name].id
  port                     = each.value.port
  protocol                 = each.value.protocol
}
