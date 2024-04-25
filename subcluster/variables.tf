variable "region" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "kubernetes" {
  type = object({
    version_prefix = string

    primary_cluster = object({
      ha = bool

      node_pool = object({
        min  = number
        max  = number
        size = string
      })

      maintenance_policy = object({
        start_time = string
        day        = string
      })
    })


    monitoring_cluster = object({
      ha = bool

      node_pool = object({
        min  = number
        max  = number
        size = string
      })

      maintenance_policy = object({
        start_time = string
        day        = string
      })
    })
  })
}

variable "postgres" {
  type = object({
    size               = string
    capacity_gib       = number
    standby_node_count = number
    version            = number

    maintenance_policy = object({
      start_time = string
      day        = string
    })
  })
}


