variable "fss" {
  type = map(object({
    availability_domain = string
    compartment_id      = string
    exports = map(object({
      path = string # The path to export
      options = map(object({
        source                 = string
        access                 = string
        optionals              = any # this must be a map(any) however, due to a bug, it has to be marked as any
        # The followings are the keys for the optionals with defaults in brackets
        # require_privileged_source_port = bool ("true")
        # identity_squash                = string ("ROOT")
        # anonymous_gid                  = number ("65534")
        # anonymous_uid                  = number ("65534")
      }))
    }))
  }))

  description = <<EOF
    availability_domain: Where to create the FSS
    compartment_id: compartment where FSS is created
    exports: Map of objects of exports
      path: the path to export in this file system
      options: Map of objects that specify options for clients connecting to this export
        source: IPv4 of the client connecting to this export
        access: permissions on the exported path for the connected client
        optionals: some configurable parameters, leave empty {} if defaults are fine
          list of configurable params:
            require_privileged_source_port = bool ("true")
            identity_squash                = string ("ROOT")
            anonymous_gid                  = number ("65534")
            anonymous_uid                  = number ("65534")
  EOF
}

variable "mount_target" {
  type = object({
    hostname_label      = string
    subnet_id           = string
    nsg_ids             = list(string)
    availability_domain = string
    compartment_id      = string
  })

  description = <<EOF
    hostname_label: the hostname for the mount target so it can be used FQDN.
    subnet_id: subnet id to create the mount target in
    nsg_ids: list of network security groups to apply to the mount target
    availability_domain: AD for the mount target
    compartment_id: compartment where mount target is created
  EOF
}
