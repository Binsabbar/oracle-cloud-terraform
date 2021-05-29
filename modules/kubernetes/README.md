
# Kuberentes
The module allows you to create a kuberentes cluster alongside its worker nodes pool. Note that, this is using the old way of creating cluster, where kube-api is by default having public IP. Oracle has already introduced a new setup, where kube-api will not be accesiable publically.

Using this module, you are limited to one a cluster, to create multiple clusters, use the modules multiple times with different names.

## Important node about updating node pools shapes
When the node pool configuration is updated, the existing worker nodes will keep their old shape, however, any newly created node will have the newest configurations. This is the same behaviour when done via Oracle Console.

## Example
Creating a cluster with 2 node pools
```h
module "kubernetes" {
  source = PATH_TO_MODULE

  vcn_id                      = "ocixxxxxx.xxxxxx.xxxxx"
  compartment_id              = "ocixxxxxx.xxxxxx.xxxxx"
  cluster_name                = "kubernetes"
  enable_kubernetes_dashboard = false
  lb_subnet_ids               = ["ocixxxxxx.xxxxxx.xxxxx", "ocixxxxxx.xxxxxx.xxxxx"]
  k8s_version                 = "v1.18.10"
  node_pools                  = {
    "node-pool-a" = {
      compartment_id      = "ocixxxxxx.xxxxxx.xxxxx"
      ssh_public_key      = "ssh-rsa xxxxxxxxxx"
      availability_domain = "ocixxxxxx.xxxxxx.xxxxx"
      subnet_id           = "ocixxxxxx.xxxxxx.xxxxx"
      shape               = "VM-XXXXXx"
      size                = 2
      image_id            = "ocixxxxxx.xxxxxx.xxxxx"
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
      size                = 4
      image_id            = "ocixxxxxx.xxxxxx.xxxxx"
      labels = {
        "my-label" : "k8s-label"
      }
    }
  }
}

```