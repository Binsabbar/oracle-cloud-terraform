# Common Config

The module contains static variables for oracle specefic IDs. Some of these IDs can easily be retrieved directly from Oracle using terraform `data`. However, no harm in hard-coding them.

Check `output.tf` for the list of static Ids this module provides.

## Example
your `main.tf` file:
```h
module "common_config" {
  source = PATH_TO_MODULE
}

locals {

  ubuntu_image_id = module.common_config.instance_config.images_ids.ubuntu_20

}
```