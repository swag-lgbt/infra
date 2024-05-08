terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
  }
}

# TODO: get this from tofu somehow....
locals {
  cloudflare_account_id = "8046ced7e2c70129d1732280998af108"
}

data "cloudflare_zone" "swag_lgbt" {
  account_id = local.cloudflare_account_id
  zone_id    = "243f037e4db09925df6e0c04681b4971"
}
