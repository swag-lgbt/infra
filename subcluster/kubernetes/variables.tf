variable "cluster" {
  type = object({
    version_prefix = string
    region         = string
    vpc_uuid       = string
  })
}

variable "node_pool" {
  type = object({
    min_nodes = number
    max_nodes = number
    size      = string
  })

  validation {
    condition     = var.node_pool.min_nodes >= 1
    error_message = "Must assign at least one node"
  }
}

variable "maintenance_policy" {
  type = object({
    start_time = string
    day        = string
  })
}
