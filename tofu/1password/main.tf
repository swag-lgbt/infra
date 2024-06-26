terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.0"
    }
  }
}


data "onepassword_vault" "swag_lgbt" {
  name = "swagLGBT"
}

# TODO(BLOCKED): https://github.com/1Password/terraform-provider-onepassword/issues/52
# all 1password items need to be "password"s :(

data "onepassword_item" "digitalocean_access_token" {
  vault = data.onepassword_vault.swag_lgbt.uuid
  title = "Tofu - DigitalOcean Access Token"
}

data "onepassword_item" "cloudflare_api_token" {
  vault = data.onepassword_vault.swag_lgbt.uuid
  title = "Tofu - Cloudflare API Token"
}

data "onepassword_item" "onepassword_service_account_token" {
  vault = data.onepassword_vault.swag_lgbt.uuid
  title = "1Password Service Account Token (Password)"
}
