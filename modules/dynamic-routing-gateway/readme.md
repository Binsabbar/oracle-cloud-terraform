# Dynamic Routing Gateway
This module allows you create a single DRG with multiple DRG VCN attachments.

Using this module, you are limited to one DRG, to create multiple DRGs, use the module multiple times with different names.

## How to use the module
This module is flexible, and depends on what you pass to it. Refer to `variables.tf` to understand what the module accepts.

Use `var.drg.name` and `var.compartment` to create the DRG only. To create VCN attachments for this DRG, use `var.drg.attachments`.

## Limitations
- Only one DRG per module is supported.
- Only `VCN` attachment type is supported for the `drg_attachment` resource.
- Does not support `drg_route_table` creation, however it can be referenced in the DRG attachments using `var.drg.attachments.optionals.drg_route_table_id`.

## Example
Create a DRG with one attachment
```h
module "drg" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  drg = {
    name = "DRG"
    attachments = {
      "drg-attachment-a-vcn" = {
        vcn_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
    }
  }
}
```

Create a DRG with multiple attachments and DRG route tables & VCN route tables
```h
module "drg" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  drg = {
    name = "DRG"
    attachments = {
      "drg-attachment-a-vcn" = {
        vcn_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
      "drg-attachment-b-vcn" = {
        vcn_id = "ocixxxxxx.xxxxxx.xxxxx"
        optionals = {
          route_table_id = "ocixxxxxx.xxxxxx.xxxxx"
          vcn_route_type = "SUBNET_CIDRS"
        }
      }
      "drg-attachment-c-vcn" = {
        vcn_id = "ocixxxxxx.xxxxxx.xxxxx"
        optionals = {
          drg_route_table_id = "ocixxxxxx.xxxxxx.xxxxx"
          route_table_id     = "ocixxxxxx.xxxxxx.xxxxx"
          vcn_route_type     = "VCN_CIDRS"
        }
      }
    }
  }
}