terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.4"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
  }
}

# PROVIDERS

provider "onepassword" {
  service_account_token = var.onepassword_service_account_token
}

provider "digitalocean" {
  token = module.credentials.digitalocean.token
}

provider "cloudflare" {
  api_token = module.credentials.cloudflare.api_token
}

provider "kubernetes" {
  host                   = module.credentials.kubernetes.host
  token                  = module.credentials.kubernetes.token
  cluster_ca_certificate = module.credentials.kubernetes.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.credentials.kubernetes.host
    token                  = module.credentials.kubernetes.token
    cluster_ca_certificate = module.credentials.kubernetes.cluster_ca_certificate
  }
}

# Modules
#
# NOTICE: modules should be named in snake_case, not kebab-case
# on account of this issue: https://github.com/helm/helm/issues/9731

module "credentials" {
  source = "./credentials"

  onepassword_service_account_token = var.onepassword_service_account_token
  kubernetes_cluster_name           = module.doks_cluster.cluster_name
}

module "doks_cluster" {
  source = "./doks_cluster"

  name   = "swag-lgbt"
  region = var.digitalocean_region

  version_prefix = var.k8s_version_prefix
  node_size_slug = var.doks_node_slug
  max_nodes      = var.max_k8s_nodes
}

# TODO: https://discuss.hashicorp.com/t/multiple-plan-apply-stages/8320/7

module "secrets_injector" {
  source = "./secrets_injector"

  service_account_token = module.credentials.onepassword.service_account_token
}
