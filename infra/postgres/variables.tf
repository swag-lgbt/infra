variable "cluster" {
  type = object({
    name   = string
    region = string

    version = number

    vpc = object({
      id = string
    })

    maintenance_policy = object({
      day        = string
      start_time = string
    })

    storage_size_gib = number
  })
}

variable "nodes" {
  type = object({
    primary = object({
      size = string
    })

    failover = optional(object({
      count = number
    }), { count = 0 })
  })
}

variable "firewall" {
  type = object({
    apps = optional(list(object({
      id = string
    })), [])

    droplets = optional(list(object({
      id = string
    })), [])

    kubernetes_clusters = optional(list(object({
      id = string
    })), [])

    ip_addrs = optional(list(string), [])

    tags = optional(list(string), [])
  })
}

variable "onepassword" {
  type = object({
    vault_uuid = string,

    admin_credentials = object({
      title = string
      tags  = set(string)
    })
  })
}
