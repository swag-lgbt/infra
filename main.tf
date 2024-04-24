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
  }
}

locals {
  project_name = "swag-lgbt"
  digitalocean_region = "nyc3"
}

# Digitalocean resources are like, "base-level", so we need to initialize them first before k8s stuff
# provider "digitalocean" {
#   token = var.digitalocean_access_token
# }

module "doks-cluster" {
  source         = "./doks-cluster"

  name   = local.project_name
  region = local.digitalocean_region

  version_prefix    = var.k8s_version_prefix
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