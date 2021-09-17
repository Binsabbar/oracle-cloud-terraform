variable "vaults" {
  type = map(object({
    name = string
    compartment_id = string
    type = string
    keys = map(object({
      name = string
      compartment_id = string
      length = string
      algorithm = string
      state = string
      mode = string
    }))
  }))

  default = {}
}

# when you restore, existing keys must be improted to terraform state manually
#TODO v3 support key restoration from file/object storage
variable "file_restored_vaults" {
  type = map(object({
    name = string
    compartment_id = string
    type = string
    file = object({
      content_length = string
      content_md5 = string
      content = string
    })
    keys = map(object({
      name = string
      compartment_id = string
      length = string
      algorithm = string
      state = string
      mode = string
    }))
  }))

  default = {}
}

variable "object_store_restored_vaults" {
  type = map(object({
    name = string
    compartment_id = string
    type = string
    oci_object_store = object({
      bucket = string
      destination = string
      namespace = string
      object = string
      uri = string
    })
    keys = map(object({
      name = string
      compartment_id = string
      length = string
      algorithm = string
      state = string
      mode = string
    }))
  }))

  default = {}
}