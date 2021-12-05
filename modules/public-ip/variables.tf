variable "compartment_id" {
  type        = string
  description = "oci of the compartment"
}

variable "untracked_ips" {
  type        = list(string)
  default     = []
  description = <<EOF
    This is a list of IPs NAMES that will NOT be assigned to private IPs by Terraform. Terraform IGNORES changes made to private IP assignment (check README.md)
  EOF
}

variable "tracked_ips" {
  type = map(object({
    private_ip_id = string
    name          = string
  }))
  default     = {}
  description = <<EOF
    Map of private IP id to assign to the created public IP. Terraform manages private IP assignments and TRACKS changes (check README.md)
  EOF
}
