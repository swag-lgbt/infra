terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.0"
    }
  }
}

# Unfortunately, you cannot currently pop out an SSH key...
# TODO: https://github.com/1Password/terraform-provider-onepassword/pull/158


data "onepassword_item" "tunnel_ssh_key" {
  vault = var.onepassword.vault_uuid
  title = var.onepassword.tunnel_ssh_key.title
  uuid  = var.onepassword.tunnel_ssh_key.uuid
}

resource "digitalocean_ssh_key" "tunnel" {
  name = data.onepassword_item.tunnel_ssh_key.title
  # public_key = data.onepassword_item.tunnel_ssh_key.public_key
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmTNrm6zX5J9t30zDcNGvHzPGw9MqbhTL//rukhNRba"
}

resource "digitalocean_droplet" "tunnel" {
  region   = var.digitalocean.region
  vpc_uuid = var.digitalocean.vpc.id

  image = var.digitalocean.droplet.image
  name  = var.digitalocean.droplet.name
  size  = var.digitalocean.droplet.size

  ipv6          = true
  resize_disk   = false
  droplet_agent = true

  ssh_keys = [digitalocean_ssh_key.tunnel.id]
  tags     = var.digitalocean.droplet.tags
}
