
variable "policies" {
  type = map(object({
    additional_domains = list(string)
    compartment_id     = string
    domain             = string

    origins = object({
      label = string
      uri   = string
    })

    policy_config = object({
      certificate_id                = string
      cipher_group                  = string
      is_behind_cdn                 = bool
      is_cache_control_respected    = bool
      is_origin_compression_enabled = bool
      is_response_buffering_enabled = bool
      is_sni_enabled                = bool
      optionals                     = map(any)
    })
    optionals = map(any)
    # The followings are the keys for the optionals with defaults in brackets
    # device_fingerprint_challenge_enabled = bool ("false")
    # human_interaction_challenge_enabled = bool ("false")
    # js_challenge_enabled = bool ("false")
  }))
}
