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
  service_account_token = var.onepassword.service_account_token
}

# TODO(BLOCKED): https://github.com/1Password/terraform-provider-onepassword/issues/52
# all 1password items need to be "password"s...

data "onepassword_vault" "swag_lgbt" {
  name = "swagLGBT"
}

data "onepassword_item" "digitalocean_access_token" {
  vault = data.onepassword_vault.swag_lgbt.uuid
  title = "Tofu - DigitalOcean Access Token"
}

data "onepassword_item" "cloudflare_api_token" {
  vault = data.onepassword_vault.swag_lgbt.uuid
  title = "Tofu - Cloudflare API Token"
}

data "digitalocean_kubernetes_cluster" "swag_lgbt" {
  name = var.kubernetes.cluster.name
}

data "digitalocean_database_cluster" "swag_lgbt" {
  name = var.postgres.name
}


resource "onepassword_item" "postgres_admin" {
  vault = data.onepassword_vault.swag_lgbt.uuid

  title = "DigitalOcean Managed Postgres"

  category = "database"
  type     = "postgresql"

  database = data.digitalocean_database_cluster.swag_lgbt.database
  hostname = data.digitalocean_database_cluster.swag_lgbt.host
  port     = data.digitalocean_database_cluster.swag_lgbt.port

  username = data.digitalocean_database_cluster.swag_lgbt.user
  password = data.digitalocean_database_cluster.swag_lgbt.password

  tags = ["DigitalOcean"]
}

# TODO: Once we can synchronize SSH keys, we should...
