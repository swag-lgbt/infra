terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
  }
}

locals {
  root_dir = trimprefix(path.module, path.root)
}

resource "cloudflare_pages_project" "auth" {
  account_id = var.cloudflare.account_id
  name       = var.cloudflare.project_name

  production_branch = "main"

  build_config {
    build_command   = "pnpm build"
    destination_dir = "dist"
    root_dir        = local.root_dir
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

resource "cloudflare_pages_domain" "auth" {
  account_id   = var.cloudflare.account_id
  domain       = "${var.subdomain}.swag.lgbt"
  project_name = cloudflare_pages_project.auth.name
}

resource "cloudflare_record" "auth" {
  zone_id = var.cloudflare.zone_id
  name    = var.subdomain
  value   = cloudflare_pages_project.auth.subdomain
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
