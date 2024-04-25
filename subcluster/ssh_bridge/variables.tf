variable "region" {
  type = string
}

variable "vpc_uuid" {
  type = string
}

variable "droplet" {
  type = object({
    name     = string
    size     = string
    ssh_keys = list(string)
  })
}
