variable "region" {
  type = string
}

variable "vpc_uuid" {
  type = string
}

variable "primary_cluster" {
  type = object({
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
}

variable "version_prefix" {
  type = string
}

variable "monitoring_cluster" {
  type = object({
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
}
