variable "region" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "kubernetes" {
  type = object({
    cluster = object({
      version_prefix = string
    })

    node_pool = object({
      min_nodes = number
      max_nodes = number
      size      = string
    })

    maintenance_policy = object({
      start_time = string
      day        = string
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


