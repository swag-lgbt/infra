variable "onepassword" {
  type = object({
    service_account_token = string
    vault_uuid            = string
  })

  sensitive = true
}

variable "postgres" {
  type = object({
    cluster_id = string
  })
}
