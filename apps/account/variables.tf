variable "cloudflare" {
  type = object({
    account_id   = string
    project_name = string
    zone_id      = string
  })
}

variable "subdomain" {
  type = string
}
