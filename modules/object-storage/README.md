# Object Storage

Create Object Storage buckets and output list of urls for all buckets. This module is self documented, check `variables.tf`. The example below uses object lifecycle rules for `DELETE`, `INFREQUENT_ACCESS`, `ARCHIVE` and `ABORT`.
This module supports bucket replication between oci regions. 

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
        "nfrequent-access-after-100-days" = {
          name               = "nfrequent-access-after-100-days"
          action             = "INFREQUENT_ACCESS"
          enabled            = true
          target             = "objects"
          time               = 100
          time_unit          = "DAYS"
          exclusion_patterns = []
          inclusion_patterns = []
          inclusion_prefixes = []
        }
        "archive-300-days" = {
          name               = "archive-300-days"
          action             = "ARCHIVE"
          enabled            = true
          target             = "objects"
          time               = 300
          time_unit          = "DAYS"
          exclusion_patterns = []
          inclusion_patterns = []
          inclusion_prefixes = []
        }
      }
      optionals      = {
        object_events_enabled = false 
        versioning_enabled = true
        replication_policy = {
          name                    = "replicate_my_website_images_to_riyadh"
          destination_region      = "me-riyadh-1"
          destination_bucket_name = "my-website-images"
        }
      }
    }

    "my-mobile-app-images" = {
      name           = "my-mobile-app-images"
      compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
      storage_tier   = "Standard"
      is_public      = true
      lifecycle_rules = {
        "rm-90-days-old" = {
          name               = "rm-90-days-old"
          action             = "DELETE"
          enabled            = true
          target             = "objects"
          time               = 90
          time_unit          = "DAYS"
          exclusion_patterns = []
          inclusion_patterns = []
          inclusion_prefixes = []
        }
        "rm-uncommited-upload" = {
          name               = "rm-uncommited-upload"
          action             = "ABORT"
          enabled            = true
          target             = "multipart-uploads"
          time               = 5
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