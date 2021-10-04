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
      lifecycle_rules = {
        "test-1" = {
          name               = "test"
          action             = "DELETE"
          enabled            = true
          target             = "objects"
          time               = 1
          time_unit          = "DAYS"
          exclusion_patterns = []
          inclusion_patterns = []
          inclusion_prefixes = []

        }
      }
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
      lifecycle_rules = {
        "test-2" = {
          name               = "test2"
          action             = "ARCHIVE"
          enabled            = true
          target             = "objects"
          time               = 1
          time_unit          = "DAYS"
          exclusion_patterns = []
          inclusion_patterns = []
          inclusion_prefixes = []

        }
      }
      optionals      = {}
    }
  }
}
```