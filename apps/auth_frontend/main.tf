terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
  }
}

resource "cloudflare_pages_project" "auth_frontend" {
  account_id = var.cloudflare.account_id
  name       = var.cloudflare.project_name

  production_branch = "main"

  build_config {
    build_command   = "pnpm build"
    destination_dir = "${var.out_dir}/${var.cloudflare.project_name}"
    root_dir        = trimprefix(path.module, path.root)
  }

  deployment_configs {
    production {
      always_use_latest_compatibility_date = true
    }
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

resource "cloudflare_pages_domain" "auth_frontend" {
  account_id   = var.cloudflare.account_id
  domain       = "${var.subdomain}.swag.lgbt"
  project_name = cloudflare_pages_project.auth_frontend.name
}

resource "cloudflare_record" "auth_frontend" {
  zone_id = var.cloudflare.zone_id
  name    = var.subdomain
  value   = cloudflare_pages_project.auth_frontend.subdomain
  type    = "CNAME"
  proxied = true
  ttl     = 3600
}
