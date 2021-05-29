locals {
  /*
  [
    { backend_set = group-a, ip = "10.0.0.1", port: 90 },
    { backend_set = group-a, ip = "10.0.0.2", port: 90 },
    { backend_set = group-b, ip = "10.0.1.1", port: 80 },
  ]
  */
  flattened_tcp_server_backends = flatten([
    for backend_set, config in var.tcp_configurations : [
      for backend in config.backends : {
        backend_set = backend_set
        ip          = backend.ip
        port        = backend.port
      }
    ]
  ])

  /*
  [
    {backend_set = group-a, virtual_host = example.com},
    {backend_set = group-a, virtual_host = *.example.com}
    {backend_set = group-b, virtual_host = abc.com},
    {backend_set = group-b, virtual_host = *.abc.com}
  ]
  */
  flattened_tcp_virtual_hosts = flatten([
    for backend_set, config in var.tcp_configurations : [
      for virtual_host in config.virtual_hosts : {
        backend_set  = backend_set
        virtual_host = virtual_host
      }
    ]
  ])

  /*
    {
      "group-a": ["group-a:example.com", "group-a:*.example.com"],
      "group-b": ["group-b:abc.com", "group-b:*.abc.com"],
    }
  */
  oci_load_balancer_hostname_names = {
    for backend_set, config in var.tcp_configurations :
    "${backend_set}" => [for virtual_host in config.virtual_hosts : "${backend_set}:${virtual_host}"]
  }
}