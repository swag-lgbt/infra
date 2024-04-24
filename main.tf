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
      version = "~> 1.4.3"
    }
  }
}

# PROVIDERS

provider "onepassword" {
  service_account_token = var.onepassword_service_account_auth_token
}

provider "digitalocean" {
  token = module.credentials.digitalocean.token
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

module "credentials" {
  source = "./credentials"

  onepassword_service_account_token = var.onepassword_service_account_auth_token
  kubernetes_cluster_name           = module.doks-cluster.cluster_name
}

module "doks-cluster" {
  source = "./doks-cluster"

  name   = "swag-lgbt"
  region = var.digitalocean_region

  version_prefix = var.k8s_version_prefix
  node_size_slug = var.doks_node_slug
  max_nodes      = var.max_k8s_nodes
}

# TODO: https://discuss.hashicorp.com/t/multiple-plan-apply-stages/8320/7

