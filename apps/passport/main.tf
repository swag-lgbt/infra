terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.4"
    }
  }
}

data "onepassword_item" "stytch_api_subdomain" {
  vault = var.onepassword.vault_uuid
  title = "Stytch API Subdomain"
}



resource "cloudflare_pages_project" "passport" {
  account_id = var.cloudflare.account_id
  name       = var.cloudflare.project_name

  production_branch = "main"

  build_config {
    build_command   = "pnpm pages:build"
    destination_dir = ".vercel/output/static"
    root_dir        = trimprefix(path.module, path.root)
    build_caching   = true
  }

  source {
    type = "github"
    config {
      owner     = "swagLGBT"
      repo_name = "swagLGBT"

      production_branch   = "main"
      deployments_enabled = true
    }
  }
}

resource "cloudflare_pages_domain" "passport" {
  account_id   = var.cloudflare.account_id
  domain       = "${var.passport.subdomain}.swag.lgbt"
  project_name = cloudflare_pages_project.passport.name
}

resource "cloudflare_record" "passport" {
  zone_id = var.cloudflare.zone_id
  name    = var.passport.subdomain
  value   = cloudflare_pages_project.passport.subdomain
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "stytch" {
  zone_id = var.cloudflare.zone_id
  name    = "api.stytch"
  value   = "${data.onepassword_item.stytch_api_subdomain.username}.customers.stytch.com"
  type    = "CNAME"
  proxied = false
  ttl     = 3600
}
