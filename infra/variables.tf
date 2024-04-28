variable "region" {
  type        = string
  description = "The DigitalOcean region to deploy infrastructure to."
}

variable "project_name" {
  type        = string
  description = "A common string prefix to use for identifying resources"
  default     = "swag-lgbt"
}

variable "onepassword_vault_uuid" {
  type      = string
  sensitive = true
}

variable "kubernetes" {
  type = object({
    ha = bool

    version_prefix = optional(string)
    maintenance_policy = object({
      start_time = string
      day        = string
    })

    node = object({
      size = string

      pool = object({
        auto_scale = optional(object({
          from = number
          to   = number
        }))

        node_count = optional(number)
      })
    })
  })
}

variable "postgres" {
  type = object({
    version = number
    maintenance_policy = object({
      start_time = string
      day        = string
    })

    storage_size_gib = number

    nodes = object({
      primary = object({
        size = string
      })

      failover = optional(object({
        count = number
      }))
    })
  })
}
