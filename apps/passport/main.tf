terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.0"
    }
  }
}

#
# This project deals with Single-Sign on, and our SSO provider is Stytch.
# So we'll want to get our credentials from them to use in other config stuff here.
#

data "onepassword_item" "stytch" {
  vault = var.onepassword.vault_uuid
  title = "Stytch Credentials"
}

#
# This section deals with setting our custom domain for OAuth in prod.
# There's no dedicated docs about it, but they have a feature where you can
# create a CNAME record from `api.stytch.<YOUR_DOMAIN>` to `<RANDOM_WORDS>.customers.stytch.com`
# and it'll change the "stytch.com" shown in OAuth logins to "swag.lgbt"
#

locals {
  oauth_custom_domain_section_index = index(data.onepassword_item.stytch.section.*.label, "OAuth Custom Domain")
  oauth_custom_domain_section       = data.onepassword_item.stytch.section[local.oauth_custom_domain_section_index].field
  oauth_custom_domain_name_index    = index(local.oauth_custom_domain_section.*.label, "name")
  oauth_custom_domain_value_index   = index(local.oauth_custom_domain_section.*.label, "value")

  # These aren't actually sensitive, since anyone can see them by just getting DNS records for swag.lgbt
  oauth_custom_domain = {
    name  = nonsensitive(local.oauth_custom_domain_section[local.oauth_custom_domain_name_index].value),
    value = nonsensitive(local.oauth_custom_domain_section[local.oauth_custom_domain_value_index].value)
  }
}

resource "cloudflare_record" "stytch" {
  zone_id = var.cloudflare.zone_id
  name    = local.oauth_custom_domain.name
  value   = local.oauth_custom_domain.value
  type    = "CNAME"
  proxied = false
  ttl     = 3600
}

#
# Now we're into setting up domain names for our Cloudflare Pages project.
# We need two resources, one to create a subdomain, and one to assign
# that subdomain to our project.
#

resource "cloudflare_record" "passport" {
  zone_id = var.cloudflare.zone_id
  name    = var.passport.subdomain
  value   = cloudflare_pages_project.passport.subdomain
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_pages_domain" "passport" {
  account_id   = var.cloudflare.account_id
  domain       = "${var.passport.subdomain}.swag.lgbt"
  project_name = cloudflare_pages_project.passport.name
}

#
# Now we're into configuring the cloudflare pages project proper
#

# Use consistent versions for Node and PNPM between local development (volta)
# and production (cloudflare pages) by setting environment variables
# that read off of what we've got in prod
locals {
  root_package_json = jsondecode(file("${path.root}/package.json"))
  node_version      = local.root_package_json.volta.node
  pnpm_version      = local.root_package_json.volta.pnpm
}

# Pull our stytch credentials from 1password and make them available to our pages project
locals {
  prod_env_section_index = index(data.onepassword_item.stytch.section.*.label, "Live Environment")
  prod_env_section       = data.onepassword_item.stytch.section[local.prod_env_section_index].field

  preview_env_section_index = index(data.onepassword_item.stytch.section.*.label, "Test Environment")
  preview_env_section       = data.onepassword_item.stytch.section[local.prod_env_section_index].field

  stytch_credentials = {
    prod = {
      public_token       = local.prod_env_section[index(local.prod_env_section.*.label, "Public token")].value
      oauth_redirect_uri = local.prod_env_section[index(local.prod_env_section.*.label, "OAuth redirect URI")].value
    }

    preview = {
      public_token       = local.preview_env_section[index(local.prod_env_section.*.label, "Public token")].value
      oauth_redirect_uri = local.preview_env_section[index(local.prod_env_section.*.label, "OAuth redirect URI")].value
    }
  }
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
        # Build vars
        NODE_VERSION = local.node_version
        PNPM_VERSION = local.pnpm_version
      }

      secrets = {
        OAUTH_REDIRECT_URI  = local.stytch_credentials.prod.oauth_redirect_uri
        STYTCH_PUBLIC_TOKEN = local.stytch_credentials.prod.public_token
      }
    }

    preview {
      environment_variables = {
        # Build vars
        NODE_VERSION = local.node_version
        PNPM_VERSION = local.pnpm_version
      }

      secrets = {
        OAUTH_REDIRECT_URI  = local.stytch_credentials.preview.oauth_redirect_uri
        STYTCH_PUBLIC_TOKEN = local.stytch_credentials.preview.public_token
      }
    }
  }
}
