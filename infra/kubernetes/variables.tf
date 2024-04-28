variable "digitalocean" {
  type = object({
    region = string

    vpc = object({
      id = string
    })
  })
}

variable "cluster" {
  type = object({
    ha             = bool
    version_prefix = string
    name           = string

    maintenance_policy = object({
      start_time = string
      day        = string
    })

    node = object({
      size = string

      pool = object({
        name = string

        auto_scale = optional(object({
          from = number,
          to   = number,
        }))

        node_count = optional(number)
      })
    })
  })

  validation {
    condition     = var.cluster.node.pool.auto_scale != var.cluster.node.pool.node_count
    error_message = "exactly one of \"pool\" and \"count\" must be specified"
  }
}
