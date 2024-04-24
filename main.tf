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

provider "onepassword" {
  alias                 = "swag_lgbt_service_account"
  service_account_token = var.onepassword_service_account_auth_token
}

module "credentials" {
  source = "./credentials"

  providers = {
    onepassword = onepassword.swag_lgbt_service_account
  }
}


provider "digitalocean" {
  alias = "swag_lgbt_access_token"
  token = module.credentials.digitalocean_access_token
}


locals {
  project_name        = "swag-lgbt"
  digitalocean_region = "nyc3"
}

module "doks-cluster" {
  source = "./doks-cluster"

  name   = local.project_name
  region = local.digitalocean_region

  version_prefix = var.k8s_version_prefix
  node_size_slug = var.doks_node_slug
  max_nodes      = var.max_k8s_nodes

  providers = {
    digitalocean = digitalocean.swag_lgbt_access_token
  }
}

# TODO: this fails if the cluster isn't running already...
# https://discuss.hashicorp.com/t/multiple-plan-apply-stages/8320/7

module "kubernetes-config" {
  source = "./kubernetes-config"

  # `cluster_name` and `cluster_id` need to be sourced from the `"doks_cluster"` module,
  # not the main module, so that opentofu can figure out that it needs to provision the cluster
  # before it can put stuff on it
  cluster_name = module.doks-cluster.cluster_name
  cluster_id   = module.doks-cluster.cluster_id

  write_kubeconfig = var.write_kubeconfig

    providers = {
    digitalocean = digitalocean.swag_lgbt_access_token
  }
}

provider "kubernetes" {
  alias = "doks"

  host                   = module.kubernetes-config.host
  token                  = module.kubernetes-config.token
  cluster_ca_certificate = module.kubernetes-config.cluster_ca_certificate
}

provider "helm" {
  alias = "doks"

  kubernetes {
    host                   = module.kubernetes-config.host
    token                  = module.kubernetes-config.token
    cluster_ca_certificate = module.kubernetes-config.cluster_ca_certificate
  }
}


# module "chat-server" {
#   source = "./chat-server"

#   providers = {
#     kubernetes = kubernetes.doks
#     helm       = helm.doks
#   }
# }