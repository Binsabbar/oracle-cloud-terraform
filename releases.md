# V2:
**Breaking Changes***
* `object-storage` module input is updated to include configuration for `lifecycle` managements.
  * Add the following key to every bucket created `lifecycle-rules = {}`. To configure rules, refer to module's readme.

## New
* Add `vault` module to manage KMS (only key management is enabled)
* (object-storage) Allow to add `lifecycle-rules` to buckets.

## Enhancement
* (instances) Allow rename of instance withour recration (breaking change)
  * You need to add `name` attribute to the instance objects you already created.
* (network) Allow display name of subnet to be updated (breaking change)
  * You need to add `name` attribute to the subnet objects you already created.
