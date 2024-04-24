terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.4.3"
    }
  }
}

data "onepassword_vault" "swag_lgbt" {
  name = "swagLGBT"
}

data "onepassword_item" "digitalocean_access_token" {
  vault = data.onepassword_vault.swag_lgbt.uuid
  title = "DigitalOcean Terraform PAT"
}