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

# For production OAuth, we can use the swagLGBT domain instead of a stytch.com one
data "onepassword_item" "stytch_api_subdomain" {
  vault = var.onepassword.vault_uuid
  title = "Stytch API Subdomain"
}

resource "cloudflare_record" "stytch" {
  zone_id = var.cloudflare.zone_id
  name    = "api.stytch"
  value   = data.onepassword_item.stytch_api_subdomain.username
  type    = "CNAME"
  proxied = false
  ttl     = 3600
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

resource "cloudflare_pages_project" "passport" {
  account_id = var.cloudflare.account_id
  name       = var.cloudflare.project_name

  production_branch = "main"

  source {
    type = "github"
    config {
      owner     = "swagLGBT"
      repo_name = "swagLGBT"

      production_branch   = "main"
      deployments_enabled = true
    }
  }

  build_config {
    build_command   = "pnpm build"
    destination_dir = "dist"
    root_dir        = trimprefix(path.module, path.root)
    build_caching   = true
  }

  deployment_configs {
    production {
      environment_variables = {
        OAUTH_REDIRECT_API = "https://api.stytch.swag.lgbt/v1/oauth/callback/oauth-callback-live-c24db04e-7018-4646-b66e-9bdce7194b32"
      }
    }

    preview {
      environment_variables = {
        OAUTH_REDIRECT_API = "https://test.stytch.com/v1/oauth/callback/oauth-callback-test-2b5d454f-e05d-498d-9d10-4abeb5a50591"
      }
    }
  }


}
