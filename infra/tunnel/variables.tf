variable "digitalocean" {
  type = object({
    region = string
    vpc = object({
      id = string
    })

    droplet = object({
      image = string
      name  = string
      size  = string

      tags = optional(list(string))
    })
  })
}

variable "onepassword" {
  type = object({
    vault_uuid = string
    tunnel_ssh_key = object({
      title = optional(string)
      uuid  = optional(string)
    })
  })

  sensitive = true
}
