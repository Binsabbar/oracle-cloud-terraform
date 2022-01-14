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

variable "node_pools" {
  type = map(object({
    compartment_id      = string
    ssh_public_key      = string
    availability_domain = string
    shape               = string
    size                = number
    image_id            = string
    labels              = map(string)
    subnet_id           = string
    k8s_version         = string
  }))

  description = <<EOL
  map of objects representing the node pool, where key is the name of the node pool
    compartment_id     : ocid of the compartment
    ssh_public_key     : string of ssh-rsa keys to be added to the created nodes/workers in the pool
    availability_domain: the AD to create nodes in
    shape              : machine/instance shape
    size               : size of disk in GB
    image_id           : ocid of the image
    labels             : map of key/string values to be added to the node during creation
    subnet_id          : ocid of the subnet to create the node in.
    k8s_version        : set the version of the node pool
  EOL
}
