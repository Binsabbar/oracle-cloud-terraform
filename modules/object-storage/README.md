# Object Storage

Create Object Storage buckets and output list of urls for all buckets. This module is self documented, check `variables.tf`


# Example
```h
module "buckets" {
  source = PATH_TO_MODULE

  buckets = {
    "my-website-images" = {
      name           = "my-website-images"
      compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
      storage_tier   = "Standard"
      is_public      = true
      optionals      = {
        object_events_enabled = false 
        versioning_enabled = true
      }
    }

    "my-mobile-app-images" = {
      name           = "my-mobile-app-images"
      compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
      storage_tier   = "Standard"
      is_public      = true
      optionals      = {}
    }
  }
}
```