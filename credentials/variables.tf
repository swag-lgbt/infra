

variable "onepassword" {
  type = object({
    service_account_token = string
  })

  sensitive = true
}

variable "kubernetes" {
  type = object({
    primary_cluster = object({
      name = string
    })

    monitoring_cluster = object({
      name = string
    })
  })

  sensitive = true
}

variable "postgres" {
  type = object({
    name = string
  })

  sensitive = true
}
