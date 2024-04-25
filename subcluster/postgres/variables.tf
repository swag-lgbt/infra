variable "region" {
  type = string
}

variable "vpc_uuid" {
  type = string
}

variable "standby_node_count" {
  type = number
  validation {
    condition     = var.standby_node_count >= 0 && var.standby_node_count <= 2
    error_message = "Can only assign between 0 and 2 standby nodes"
  }
}

variable "storage_size_mib" {
  type = number
}

variable "maintenance_policy" {
  type = object({
    day        = string
    start_time = string
  })
}

variable "size" {
  type = string
}

variable "pg_version" {
  type = number
}

variable "firewall" {
  type = object({
    kubernetes_clusters = set(object({
      id = string
    }))

    droplets = set(object({
      id = string
    }))
  })
}
