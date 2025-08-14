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
variable "ip_families" {
  type    = list(string)
  default = ["IPv4"]
  description = "IP family for the cluster, can be IPv4 or Pv4 and IPv6"
} 
variable "kubernetes_network_config" {
  type = object({
    pods_cidr     = optional(string)
    services_cidr = optional(string)
  })
  default = null
}

variable "endpoint_config" {
  type = object({
    is_public_ip_enabled = bool
    nsg_ids              = set(string)
    subnet_id            = string
  })

  description = <<EOF
    Configuration for cluster endpoint
    is_public_ip_enabled : attach public IP
    nsg_ids : list network security group to attach on endpoint
    subnet  : placement of cluster master node
  EOF
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
    defined_tags        = optional(map(string))
    subnet_id           = string
    k8s_version         = string
    flex_shape_config   = map(string)
    node_metadata       = map(string)
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
    defined_tags       : Defined tags for this resource. Each key is predefined and scoped to a namespace.
    subnet_id          : ocid of the subnet to create the node in.
    k8s_version        : set the version of the node pool
    flex_shape_config  : customize number of ocpus and memory when using Flex Shape
    node_metadata      : key/value for node metadata
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
