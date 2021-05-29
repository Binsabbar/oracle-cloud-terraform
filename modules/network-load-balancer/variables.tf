variable "nlbs" {
  type = map(object({
    compartment_id = string
    reserved_ip_id = string
    subnet_id      = string
    is_private     = bool
    nsg_ids        = set(string)
    listeners = map(object({
      port     = number
      protocol = string
      backend_set = object({
        backend_ips  = set(string)
        backend_port = number
        health_checker = object({
          protocol           = string
          interval_in_millis = number
          retries            = number
          timeout_in_millis  = number
        })
      })
    }))
  }))

 description = <<EOL
  map of NLB configurations, where key is used as NLB name
    compartment_id: The compartment id to create nlb in
    reserved_ip_id: ocid of the reserved public IP, leave empty if you want the module to create public IP
    subnet_id     : The ocid of the subnet to create nlb in
    is_private    : Set to true if you want to assign public IP (set reserved_ip_id to empty if you want the module to create public IP)
    nsg_ids       : list of ocid for network security groups
    listeners: map of listeners configurations, where key is used as listener name
      port    : the listener port that is exposed in the NLB
      protocol: the protocol, TCP or UDP
      backend_set: object configuration for the backend attached to this listner
        backend_ips : list of IP address for this backened set
        backend_port: the port number of the backend instances to route connection to
        health_checker: object configuration for the health checker of backends
          protocol          : which protocol to use to check the health of the backend
          interval_in_millis: how often does it check the backend health
          retries           : how many time it tries before marking backend as non healthy 
          timeout_in_millis : when to timeout when checking backend
  EOL
}
