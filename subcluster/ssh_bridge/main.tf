terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

resource "digitalocean_droplet" "ssh_bridge" {
  name   = var.droplet.name
  region = var.region

  image = "ubuntu-22-04-x64"
  size  = var.droplet.size

  ssh_keys      = var.droplet.ssh_keys
  droplet_agent = true
  monitoring    = true

  vpc_uuid = var.vpc_uuid
  ipv6     = true
}
