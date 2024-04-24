variable "version_prefix" {
  description = <<-EOT
  Prefix for the version of kubernetes to use, e.g. 1.29

  Available versions can be listed with `doctl kubernetes options versions`
  EOT

  type = string
}

variable "max_nodes" {
  type = number
}

variable "node_size_slug" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}