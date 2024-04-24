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

# The first thing to do is get access to the credentials we need to set up infrastructure
# We only pass in the one service account auth token for 1password, and keep the rest in there.
module "credentials" {
  source = "./credentials"

  service_account_token = var.onepassword_service_account_auth_token
}

# Now that we've authenticated with 1password, we can authenticate with digitalocean

provider "digitalocean" {
  token = module.credentials.digitalocean_access_token
}


locals {
  digitalocean_region = "nyc3"
}

module "doks-cluster" {
  source = "./doks-cluster"

  name   = "swag-lgbt"
  region = local.digitalocean_region

  version_prefix = var.k8s_version_prefix
  node_size_slug = var.doks_node_slug
  max_nodes      = var.max_k8s_nodes
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
}

# Once we've got kubernetes up and running, we should configure our providers to target that cluster

provider "kubernetes" {
  host                   = module.kubernetes-config.host
  token                  = module.kubernetes-config.token
  cluster_ca_certificate = module.kubernetes-config.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.kubernetes-config.host
    token                  = module.kubernetes-config.token
    cluster_ca_certificate = module.kubernetes-config.cluster_ca_certificate
  }
}

# Now we've configured
# 1. Authentication with 1password
# 2. The underlying DOKS cluster
# 3. The k8s and helm providers
#
# Time to spin up some containers!

# module "chat-server" {
#   source = "./chat-server"

#   providers = {
#     kubernetes = kubernetes.doks
#     helm       = helm.doks
#   }
# }