terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}