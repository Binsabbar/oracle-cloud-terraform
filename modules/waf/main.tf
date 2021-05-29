resource "oci_waas_waas_policy" "policies" {
  for_each = var.policies

  additional_domains = each.value.additional_domains
  compartment_id     = each.value.compartment_id
  display_name       = each.key
  domain             = each.value.domain
  origins {
    http_port  = 80
    https_port = 443
    label      = each.value.origins.label
    uri        = each.value.origins.uri
  }
  policy_config {
    certificate_id = each.value.policy_config.certificate_id
    cipher_group   = each.value.policy_config.cipher_group

    is_behind_cdn                 = each.value.policy_config.is_behind_cdn
    is_cache_control_respected    = each.value.policy_config.is_cache_control_respected
    is_https_enabled              = true
    is_https_forced               = true
    is_origin_compression_enabled = each.value.policy_config.is_origin_compression_enabled
    is_response_buffering_enabled = each.value.policy_config.is_response_buffering_enabled
    is_sni_enabled                = each.value.policy_config.is_sni_enabled
    load_balancing_method {
      method = "IP_HASH"
    }
    tls_protocols = [
      "TLS_V1_2",
      "TLS_V1_3",
    ]
  }
  waf_config {
    address_rate_limiting {
      allowed_rate_per_address      = 1
      block_response_code           = 503
      is_enabled                    = false
      max_delayed_count_per_address = 10
    }
    device_fingerprint_challenge {
      action                       = "DETECT"
      action_expiration_in_seconds = 60
      challenge_settings {
        block_action                 = "SHOW_ERROR_PAGE"
        block_error_page_code        = "DFC"
        block_error_page_description = "Access blocked by website owner. Please contact support."
        block_error_page_message     = "Access to the website is blocked."
        block_response_code          = 403
        captcha_footer               = "Enter the letters and numbers as they are shown in image above."
        captcha_header               = "We have detected an increased number of attempts to access this website. To help us keep this site secure, please let us know that you are not a robot by entering the text from the image below."
        captcha_submit_label         = "Yes, I am human."
        captcha_title                = "Are you human?"
      }
      failure_threshold                       = 10
      failure_threshold_expiration_in_seconds = 60
      is_enabled                              = lookup(each.value.optionals, "device_fingerprint_challenge_enabled", false)
      max_address_count                       = 20
      max_address_count_expiration_in_seconds = 60
    }
    human_interaction_challenge {
      action                       = "DETECT"
      action_expiration_in_seconds = 60
      challenge_settings {
        block_action                 = "SHOW_ERROR_PAGE"
        block_error_page_code        = "HIC"
        block_error_page_description = "Access blocked by website owner. Please contact support."
        block_error_page_message     = "Access to the website is blocked."
        block_response_code          = "403"
        captcha_footer               = "Enter the letters and numbers as they are shown in image above."
        captcha_header               = "We have detected an increased number of attempts to access this website. To help us keep this site secure, please let us know that you are not a robot by entering the text from the image below."
        captcha_submit_label         = "Yes, I am human."
        captcha_title                = "Are you human?"
      }
      failure_threshold                       = 10
      failure_threshold_expiration_in_seconds = 60
      interaction_threshold                   = 3
      is_enabled                              = lookup(each.value.optionals, "human_interaction_challenge_enabled", false)
      is_nat_enabled                          = true
      recording_period_in_seconds             = 15
      #set_http_header = <<Optional value not found in discovery>>
    }
    js_challenge {
      action                       = "DETECT"
      action_expiration_in_seconds = 60
      are_redirects_challenged     = true
      challenge_settings {
        block_action                 = "SHOW_ERROR_PAGE"
        block_error_page_code        = "JSC-403"
        block_error_page_description = "Access blocked by website owner. Please contact support."
        block_error_page_message     = "Access to the website is blocked."
        block_response_code          = 403
        captcha_footer               = "Enter the letters and numbers as they are shown in image above."
        captcha_header               = "We have detected an increased number of attempts to access this website. To help us keep this site secure, please let us know that you are not a robot by entering the text from the image below."
        captcha_submit_label         = "Yes, I am human."
        captcha_title                = "Are you human?"
      }
      failure_threshold = 10
      is_enabled        = lookup(each.value.optionals, "js_challenge_enabled", false)
      is_nat_enabled    = true
      set_http_header {
        name  = "x-jsc-alerts"
        value = "{failed_amount}"
      }
    }
    origin = "loadbalancer"
    origin_groups = [
    ]
    protection_settings {
      allowed_http_methods = [
        "GET",
        "PUT",
        "POST",
        "DELETE",
        "HEAD",
        "OPTIONS",
      ]
      block_action                       = "SET_RESPONSE_CODE"
      block_error_page_code              = 403
      block_error_page_description       = "Access blocked by website owner. Please contact support."
      block_error_page_message           = "Access to the website is blocked."
      block_response_code                = 403
      is_response_inspected              = false
      max_argument_count                 = 255
      max_name_length_per_argument       = 400
      max_response_size_in_ki_b          = 1024
      max_total_name_length_of_arguments = 64000
      media_types = [
        "text/html",
        "text/plain",
      ]
      recommendations_period_in_days = "10"
    }
  }
}

