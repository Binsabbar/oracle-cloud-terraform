variable "gateways" {
  type = object({
    gateways = map(string)
  })
}