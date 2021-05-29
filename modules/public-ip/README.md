# Public IP

Create and reserve public IPs in a given compartment. This module is self documented, check `variables.tf`


# Example
The following creates two public IPs with the names:
* machine-1
* prod-lb-ip

```h
module "public_ips" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  ips            = toset(["machine-1", "prod-lb-ip"])
}
```