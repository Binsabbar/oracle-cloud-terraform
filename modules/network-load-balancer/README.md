- [Network Load Balancer (NLB)](#network-load-balancer-nlb)
  - [What does the module create?](#what-does-the-module-create)
  - [Limitations](#limitations)
- [Examples](#examples)

# Network Load Balancer (NLB)
The module create an NLB with backends added to the backendsets. It alos sets the backendset for the listener. Read more about NLB concepts at oracle [here](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/overview.htm). In order to use this module you need to understand the NLB concepts.

The NLB will be created in the given subnet ID. It is possible to attach network security groups to the NLB if needed, otherwise, security list applied at subnet level will be used. Moreover, this module can be used to create public NLB with its own IP address (or pass your oci created public IP instead)

## What does the module create?
The module will create the following based on the values passed in `variables.tf`
* Network Load Balancer
* Listener
* Backend Set for Listener
* Backends
* Configure Health check for backends

## Limitations
* You can only assign 1 backendset for a listener
* The backend port is used as health check port as well (Health check port is not configurable)
* Backends are limited to IPs (using instances IDs not supported)

# Examples
Creating an NLB with the following configurations
* TCP Port 80 with single backend set
  * Backend Set: 
    * Two backends with the following IPs: 192.168.13.3 and 192.168.13.4
    * Backends port is 9090
    * Healthcheck protocol is TCP
* TCP Port 8443 with single backend set
  * Backend Set: 
    * Three backends with the following IPs: 192.168.14.3, 192.168.14.4, and 192.168.14.5
    * Backends port is 8081
    * Healthcheck protocol is TCP

```h

module "nlb" {
  source = "../../modules/network-load-balancer"
  nlbs   = {
    "nlb" = {
      compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
      subnet_id      = "ocixxxxxx.xxxxxx.xxxxx"
      is_private     = false
      nsg_ids        = ["ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx"]
      reserved_ip_id = "ocixxxxxx.xxxxxx.xxxxx"

      listeners = {
        tcp_80 = {
          port     = 80
          protocol = "TCP"
          backend_set = {
            backend_ips  = ["192.168.13.3", "192.168.13.4"]
            backend_port = 9090
            health_checker = {
              protocol           = "TCP"
              interval_in_millis = 10000
              retries            = 3
              timeout_in_millis  = 3000
            }
          }
        }

        tcp_8443 = {
          port     = 8443
          protocol = "TCP"
          backend_set = {
            backend_ips  = ["192.168.14.3", "192.168.14.4", "192.168.14.5"]
            backend_port = 8081
            health_checker = {
              protocol           = "TCP"
              interval_in_millis = 20000
              retries            = 3
              timeout_in_millis  = 4000
            }
          }
        }
      }
    }
  }
}
```
