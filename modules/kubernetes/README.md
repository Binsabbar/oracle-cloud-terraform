
# Kuberentes
The module allows you to create a kuberentes cluster alongside its worker nodes pool. Note that, this is using the old way of creating cluster, where kube-api is by default having public IP. Oracle has already introduced a new setup, where kube-api will not be accesiable publically.

Using this module, you are limited to one a cluster, to create multiple clusters, use the modules multiple times with different names.

## Important node about updating node pools shapes
When the node pool configuration is updated, the existing worker nodes will keep their old shape, however, any newly created node will have the newest configurations. This is the same behaviour when done via Oracle Console.

## Using Flex Shapes
You have the options to use AMD flex shaeps. Just set `flex_shape_config` key in `node_pools` varible per nood pool. The variable `flex_shape_config` should have the following two keys `ocpus` and `memory_in_gbs`. See example below.

Note that, Flex Shape works only with AMD shape `VM.Standard.E3.Flex` and `VM.Standard.E4.Flex`, and Intel `VM.Standard3.Flex`.

## Node sizing and Auto-scale
When you need to create a node pool for autoscale, `node_size` must be ignored by Terraform state. Hence, you need to create a pool with initial size of `0`. This will automatically ignore size changes in the pool by Terraform.

## Example
Creating a cluster with 2 node pools
```h
module "kubernetes" {
  source = PATH_TO_MODULE

  vcn_id                      = "ocixxxxxx.xxxxxx.xxxxx"
  compartment_id              = "ocixxxxxx.xxxxxx.xxxxx"
  cluster_name                = "kubernetes"
  enable_kubernetes_dashboard = false
  is_tiller_enabled           = false
  lb_subnet_ids               = ["ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx"]
  cluster_k8s_version         = "v1.18.10"
  ip_families                 = ["IPv4", "IPv6"]
  kubernetes_network_config = {
    pods_cidr     = "10.244.0.0/16, fd00:eeee:eeee::/96"
    services_cidr = "10.96.0.0/16, fd00:eeee:ffff::/112"
  }
  endpoint_config             = {
    is_public_ip_enabled = false
    nsg_ids = ["oci.xxxxxx"]
    subnet_id = "oci.xxxxxxxx"
  }
  node_pools                  = {
    "node-pool-a" = {
      compartment_id        = "ocixxxxxx.xxxxxx.xxxxx"
      ssh_public_key        = "ssh-rsa xxxxxxxxxx"
      availability_domain   = "ocixxxxxx.xxxxxx.xxxxx"
      subnet_id             = "ocixxxxxx.xxxxxx.xxxxx"
      shape                 = "VM-XXXXXx"
      node_metadata         = {}
      volume_size_in_gbs    = 500
      size                  = 2
      defined_tags          = { "Oracle-Tags.CreatedBy" = "oke"}
      k8s_version           = "v1.18.10"
      image_id              = "ocixxxxxx.xxxxxx.xxxxx"
      labels = {
        "my-label" : "k8s-label"
      }
    }

    "node-pool-b" = {
      compartment_id      = "ocixxxxxx.xxxxxx.xxxxx"
      ssh_public_key      = "ssh-rsa xxxxxxxxxx"
      availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
      subnet_id           = "ocixxxxxx.xxxxxx.xxxxx"
      shape               = "VM-XXXXXx"
      node_metadata       = {}                
      volume_size_in_gbs  = 50
      size                = 4
      defined_tags          = { "Oracle-Tags.CreatedBy" = "oke"}
      k8s_version         = "v1.18.10"
      image_id            = "ocixxxxxx.xxxxxx.xxxxx"
      flex_shape_config = {
        ocpus         = 4
        memory_in_gbs = 64
      }
      labels = {
        "my-label" : "k8s-label"
      }
    }
    "node-pool-autoscale" = {
      compartment_id      = "ocixxxxxx.xxxxxx.xxxxx"
      ssh_public_key      = "ssh-rsa xxxxxxxxxx"
      availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
      subnet_id           = "ocixxxxxx.xxxxxx.xxxxx"
      shape               = "VM-XXXXXx"
      node_metadata       = {}                
      volume_size_in_gbs  = 50
      size                = 0   # this will force terraform to ignore changes to the pool size when autoscale kicks in
      defined_tags          = { "Oracle-Tags.CreatedBy" = "oke"}
      k8s_version         = "v1.18.10"
      image_id            = "ocixxxxxx.xxxxxx.xxxxx"
      flex_shape_config = {
        ocpus         = 4
        memory_in_gbs = 64
      }
      labels = {
        "my-label" : "k8s-label"
      }
    }
  }
}

```