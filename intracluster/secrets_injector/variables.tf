
variable "onepassword" {
  type = object({
    service_account_token = string
  })

  sensitive = true
}

variable "kubernetes" {
  type = object({
    namespace = string
  })
}
