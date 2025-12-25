# Dynamic Routing Gateway
This module allows you create a single DRG with DRG route tables, DRG VCN attachments, Remote Peering Connections (RPCs), and to manage all types of DRG attachments.

Using this module, you are limited to one DRG, to create multiple DRGs, use the module multiple times with different names.

## How to use the module
This module is flexible, and depends on what you pass to it. Refer to `variables.tf` to understand what the module accepts.

- Use `var.drg.name` and `var.compartment` to create the DRG only
- Use `var.drg.route_tables` to create DRG route tables
- Use `var.drg.vcn_attachments` to create VCN attachments for this DRG
- Use `var.drg.none_vcn_attachments` to manage and configure all types of DRG attachments (Note: This does not create the attachment, instead it only configures existing attachments)
- Use `var.drg.remote_peering_connections` to create RPCs that are attached to the DRG

## Remote peering connection
To peer two RPCs together use `var.drg.remote_peering_connections.peer_connection.peer_id` and `var.drg.remote_peering_connections.peer_connection.peer_region_name` on either and ONLY either RPC. Once the connection is established and is in a `PEERED` state, you can then add `var.drg.remote_peering_connections.peer_connection.peer_id` and `var.drg.remote_peering_connections.peer_connection.peer_region_name` to the other RPC for reference (it should not change anything).


By default Oracle creates the DRG attachment with the creation of the RPC. In this module we also create a `oci_core_drg_attachment_management` resource automatically with every RPC, so whenever an RPC is deleted the `oci_core_drg_attachment_management` resource becomes invalid and will cause an error. To bypass this we added the following block to the `oci_core_drg_attachment_management` resource: -
```h
 lifecycle {
    replace_triggered_by = [oci_core_remote_peering_connection.remote_peering_connection[each.key].id]
  }
```
This will force the creation of the resource incase the RPC is destroyed

To remove two peered RPCs Oracle recommends to remove both of them, because if one of them is not destroyed it will have a `REVOKED` peering_status. If another RPC resource tries to connect to this RPC resource the peering_status on the requestor will be `INVALID`.

## Example
Create a DRG with one VCN attachment
```h
module "drg" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  drg = {
    name = "drg"
    vcn_attachments = {
      drg-attachment-a-vcn = {
        name   = "drg-attachment-a-vcn"
        vcn_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
    }
  }
}
```

Create a DRG with VCN attachments and DRG route tables & VCN route tables
```h
module "drg" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  drg = {
    name = "drg"
    route_tables = {
      name = "a-vcn-drg-route-table"
      rules = {
        destination                 = "192.168.0.0/16"
        next_hop_drg_attachment_key = "drg-attachment-a-vcn"
      }
    }
    vcn_attachments = {
      drg-attachment-a-vcn = {
        name                = "drg-attachment-a-vcn"
        vcn_id              = "ocixxxxxx.xxxxxx.xxxxx"
        drg_route_table_key = "a-vcn-drg-route-table"
      }
      drg-attachment-b-vcn = {
        name           = "drg-attachment-b-vcn"
        vcn_id         = "ocixxxxxx.xxxxxx.xxxxx"
        route_table_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
      drg-attachment-c-vcn = {
        name   = "drg-attachment-c-vcn"
        vcn_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
    }
  }
}
```

Create a DRG with RPCs and manage non-VCN DRG attachments
```h
module "drg" {
  source         = PATH_TO_MODULE
  compartment_id = "ocixxxxxx.xxxxxx.xxxxx"
  drg = {
    name = "drg"
    none_vcn_attachments_managements = {
      rpc = {
        name       = "rpc"
        type       = "REMOTE_PEERING_CONNECTION"
        network_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
      ip_sec = {
        name       = "ip_sec"
        type       = "IPSEC_TUNNEL"
        network_id = "ocixxxxxx.xxxxxx.xxxxx"
      }
    }
    remote_peering_connections = {
      rpc = {
        name = "rpc"
      }
    }
  }
}
```