variable "vcn_id" {
  type = string
}

variable "cluster_k8s_version" {
  type    = string
  default = "v1.19.15"
}

variable "compartment_id" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "name of the cluster"
}

variable "enable_kubernetes_dashboard" {
  type    = bool
  default = false
}

variable "lb_subnet_ids" {
  type        = list(string)
  description = "The Subnet IDs where svc of type LoadBalancers will have their LBs created"
}

variable "cloudinit_nodepool" {
  type = map(any)
}

variable "cloudinit_nodepool_common" {
  type = string
}

variable "worker_echo" {
  type = string
}


variable "node_pools" {
  type = map(object({
    compartment_id      = string
    ssh_public_key      = string
    availability_domain = string
    shape               = string
    size                = number
    volume_size_in_gbs  = number
    image_id            = string
    labels              = map(string)
    subnet_id           = string
    k8s_version         = string
    flex_shape_config   = map(string)
  }))

  description = <<EOL
  map of objects representing the node pool, where key is the name of the node pool
    compartment_id     : ocid of the compartment
    ssh_public_key     : string of ssh-rsa keys to be added to the created nodes/workers in the pool
    availability_domain: the AD to create nodes in
    shape              : machine/instance shape
    size               : The number of nodes that should be in the node pool.
    volume_size_in_gbs : Size of Boot volume in GB per node
    image_id           : ocid of the image
    labels             : map of key/string values to be added to the node during creation
    subnet_id          : ocid of the subnet to create the node in.
    k8s_version        : set the version of the node pool
    flex_shape_config  : customize number of ocpus and memory when using Flex Shape
  EOL


  validation {
    condition = alltrue(flatten([
      for k, v in var.node_pools : [
        for keys in keys(v.flex_shape_config) : contains(["ocpus", "memory_in_gbs"], keys)
      ]
    ]))
    error_message = "The node_pools.*.flex_shape_config accepts only \"ocpus\", \"memory_in_gbs\"."
  }
}
