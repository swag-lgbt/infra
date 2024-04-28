terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

resource "digitalocean_vpc" "main" {
  name   = var.name
  region = var.region
}
