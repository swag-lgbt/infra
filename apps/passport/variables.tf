variable "cloudflare" {
  type = object({
    account_id   = string
    project_name = string
    zone_id      = string
  })
}

variable "passport" {
  type = object({
    subdomain = string
  })
}

variable "onepassword" {
  type = object({
    vault_uuid = string
  })
}
