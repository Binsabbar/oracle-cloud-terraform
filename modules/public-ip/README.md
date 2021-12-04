# Public IP

Create and reserve public IPs in a given compartment. This module is self documented, check `variables.tf`

## `untracked_ips` vs `tracked_ips`

Use `untracked_ips` if you plan to manage private IP assignment manually (or not via Terraform). Terraform will ignore any changes made to `private_ip_id` attribute of the public kIPey. A good use case if you want to assign public IP to Network Load Balancer.

Use `tracked_ips` when you will assign the public IP to a VNIC via a known private IP. Note that you can still create `tracked_ips` without private IP assignment, and assign private IP at later time.

## Moving public IP from `untracked_ips` to `tracked_ips` and vice versa

You can migrate `tracked_ips` to `untracked_ips` and vice versa using `terraform state mv`
### Migrating `untracked_ips` to `tracked_ips`
Assuming you have the following input
```
module "my_public_ips" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  untracked_ips  = toset(["machine-1", "prod-lb-ip"])
  tracked_ips    = {}
}
```
and you want to start tracking `machine-1` public IP.
  1. Remove the `machine-1` from `untracked_ips` variable input.
  ```
  untracked_ips  = toset(["prod-lb-ip"])
  ```
  2. Create new key for `tracked_ips` with the same name `machine-1`
  ```
  tracked_ips    = { 
    "machine-1" = {
      private_ip_id = ""
      name          = "machine-1"
    }
  }
  ```
  3. Run the following (assuming you named you module `my_public_ips`):

```
terraform state mv module.my_public_ips.oci_core_public_ip.ip\[\"machine-1\"\] mv module.my_public_ips.oci_core_public_ip.tracked_ip\[\"machine-1\"\]
```

### Migrating `untracked_ips` to `tracked_ips`
Assuming you have the following input
```
module "my_public_ips" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  untracked_ips  = toset(["prod-lb-ip"])
  tracked_ips    = { 
    "machine-1" = {
      private_ip_id = ""
      name          = "machine-1"
    }
  }
}
```
and you want to STOP tracking `machine-1` public IP.
  1. Remove the `machine-1` from `tracked_ips` variable input.
  ```
  untracked_ips  = {}
  ```
  2. Create new item for `untracked_ips` with the same name `machine-1`
  ```
  untracked_ips  = toset(["prod-lb-ip", "machine-1"])
  ```
  3. Run the following (assuming you named you module `my_public_ips`):

```
terraform state mv module.my_public_ips.oci_core_public_ip.tracked_ip\[\"machine-1\"\] mv module.my_public_ips.oci_core_public_ip.ip\[\"machine-1\"\]
```
# Example
```h
module "public_ips" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  untracked_ips  = toset(["machine-1", "prod-lb-ip"])
  tracked_ips    = {
    "public_ip_a" = {
      # will NOT assign the public IP to any private IP yet
      private_ip_id = ""
      name          = "public A"
    }
    "public_ip_v" = {
      # will assign the public IP to the private IP of private_ip_id
      private_ip_id = "ocixxxxxx.xxxxxx.xxxxx"
      name          = "public B"
    }
  }
}
```