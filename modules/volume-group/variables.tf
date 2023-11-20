variable "volume_group_availability_domain" {
  description = "Volume group avilability domain"
  type        = string
}

variable "compartment_id" {
  description = "Compartment ID"
  type        = string
}

variable "name" {
  description = "Subnet name"
  type        = string
}

variable "backup_policy_id" {
  description = "Backup policy id"
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Tags to VCN"
  type        = map(any)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags to VCN"
  type        = map(any)
  default     = {}
}

variable "volume_groups" {
  description = "List with volume groups"
  type = map(object({
    volume_ids              = list(string)
    compartment_id          = optional(string)
    type                    = optional(string, "volumeIds")
    backup_policy_id        = optional(string)
    name                    = optional(string)
    volume_group_backup_id  = optional(string)
    volume_group_id         = optional(string)
    volume_group_replica_id = optional(string)
    defined_tags            = optional(any)
    freeform_tags           = optional(any)
    volume_group_replicas = optional(object({
      availability_domain = string
      display_name        = optional(string)
    }))
  }))
  default = {}
}