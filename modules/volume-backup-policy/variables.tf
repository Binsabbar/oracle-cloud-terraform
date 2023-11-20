variable "compartment_id" {
  description = "Compartment ID"
  type        = string
}

variable "name" {
  description = "Subnet name"
  type        = string
}

variable "destination_region" {
  description = "The paired destination region for copying scheduled backups to. Example: us-ashburn-1"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to VCN"
  type        = map(any)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags to VCN"
  type        = map(any)
  default     = null
}

variable "backup_schedules" {
  description = "map of object for backup schedules"
  type = map(object({
    period            = optional(string)
    hour_of_day       = optional(number, 23)
    retention_seconds = optional(number, 604800)
    backup_type       = optional(string, "INCREMENTAL")
    time_zone         = optional(string, "REGIONAL_DATA_CENTER_TIME")
    day_of_month      = optional(number)
    day_of_week       = optional(string)
    month             = optional(string)
    offset_seconds    = optional(number)
    offset_type       = optional(string)
  }))
  default = {}
}
