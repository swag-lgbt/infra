terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.4.3"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

provider "onepassword" {
  service_account_token = var.onepassword_service_account_token
}

# TODO(BLOCKED): https://github.com/1Password/terraform-provider-onepassword/issues/52
# all 1password items need to be "password"s...

data "onepassword_vault" "swag_lgbt" {
  name = "swagLGBT"
}

data "onepassword_item" "digitalocean_access_token" {
  vault = data.onepassword_vault.swag_lgbt.uuid
  title = "DigitalOcean Terraform Access Token"
}

data "digitalocean_kubernetes_cluster" "primary" {
  name = var.kubernetes_cluster_name
}