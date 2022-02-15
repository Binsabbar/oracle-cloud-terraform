# Volumes

Create and manage "Block Volumes" and their backup policies across regions. Read more about Block Volumes [here](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/overview.htm).

# Volume Attachment
Once the volume is created, you can attach it to multiple instances. By default the volume will be attached as `paravirtualized`. However you have the option to overwrite this under `volumes[].instances_attachment[].optionals.type`.

## Sharing volume with multiple instances
Ensure that you turn on the `volumes[].instances_attachment[].is_shareable` to `true`.

# Note about Backup Policy
OCI already provides its own backup policies. However, this modules DOES NOT support using existing policies. You will have to define the policy in this module to be abl to use it with a volume.

When creating a policy, you need to be careful with `backup_policies[].schedules[].optionals`. Depending on the value of `backup_policies[].schedules[].backup_type` you will need to set the `backup_policies[].schedules[].optionals` values. See example below and refer to (core_volume_backup_policy)[https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_volume_backup_policy].

# Replication
The module supports replication across another region. Just set `volumes[].cross_ad_replicas[].destination_availability_domain` and  `volumes[].cross_ad_replicas[].replica_name` as many times as you want. Ensure that you set `volumes[].disable_replicas` to `false`

# Creating Volume from other source
To create a volume from an existing volume, all you have to do is to set `volumes[].source_volume.id` and `volumes[].source_volume.type`. This makes it possible to clone an existing volume and use it as new one.

# Limitations 
* Using predefined OCI Backup Policy not supported.
* `offsetSeconds` Backup Policy are NOT supported.
*  
# Example

```js
module "opensource_volumes" {
  source          = "github.com/Binsabbar/oracle-cloud-terraform//modules/volumes"
  volumes         = {
    "volume-1" = {
      name                                = "volume-1"
      compartment_id                      = "oci.xxxxxxxxxxxxxxxxxxx"
      availability_domain                 = data.oci_identity_availability_domain.ad_1.name
      size_in_gbs                         = 50
      reference_to_backup_policy_key_name = null
      disable_replicas                    = true
      cross_ad_replicas                   = {
        "replica-1" = {
          destination_availability_domain = "me-jeddah-2"
          replica_name                    = "region-2-replica-volume1" 
        }
      }
      source_volume                       = {
        id = "oci.volume.xxxxxxxxxxxxxxxxx"
        type = "volume"
      }
      instances_attachment = {
        "instace-1" = {
          instance_id  = "oci.instance.xxxxxxxxxxxxx"
          is_shareable = true
          optionals    = {}
        }
      }
      optionals = {
        auto_tuned = true
        kms_id = "oci.kms.xxxxxxxxxxxxxxxxxxx"
        vpus_per_gb = 10
      }
    }
    "volume-2" = {
      name                                = "volume-2"
      compartment_id                      = "oci.xxxxxxxxxxxxxxxxxxx"
      availability_domain                 = data.oci_identity_availability_domain.ad_1.name
      size_in_gbs                         = 50
      reference_to_backup_policy_key_name = "everyday"
      disable_replicas                    = true
      cross_ad_replicas                   = {}
      source_volume = {}
      instances_attachment = {
        "instace-1" = {
          instance_id  = "oci.instance.xxxxxxxxxxxxx"
          is_shareable = true
          optionals    = {
            type = ""
            is_read_only = true
            is_pv_encryption_in_transit_enabled = bool
            encryption_in_transit_type = string
            use_chap = bool
          }
        }
        "instace-2" = {
          instance_id  = "oci.instance.xxxxxxxxxxxxx"
          is_shareable = false
          optionals    = {
            type = ""
            is_read_only = false
            is_pv_encryption_in_transit_enabled = true
          }
        }
      }
      optionals = {}
    }
  }
  backup_policies = {
    "SLA-1" = {
      compartment_id = "oci.xxxxxxxxxxxxxxxxxxxxx"
      name = "SLA Level 1 backup policy"
      destination_region = "me-jeddah-1"
      schedules = { 
        "daily" = {
          backup_type = "INCREMENTAL"
          period = "ONE_DAY"
          retention_seconds = 3600 * 24 # one day
          optionals = {
            hour_of_day = 23
          }
        }
        "weekly" = {
          backup_type = "FULL"
          period = "ONE_WEEK"
          retention_seconds = 3600 * 24 * 7 # one week
          optionals = {
            hour_of_day = 0
            day_of_week = "FRIDAY"
          }
        }
        "monthly" = {
          backup_type = "FULL"
          period = "ONE_MONTH"
          retention_seconds = 3600 * 24 * 30 # # one month
          optionals = {
            hour_of_day = 0
            day_of_week = "SUNDAY"
            day_of_month = 28
          }
        }
        "yearly" = {
          backup_type = "FULL"
          period = "ONE_YEAR"
          retention_seconds = 3600 * 24 * 30 * 12 # # one year
          optionals = {
            hour_of_day = 0
            day_of_week = "SUNDAY"
            day_of_month = 30
            month = "DECEMBER"
          }
        }
      }
    }
  }
}
```