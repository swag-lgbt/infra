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

##########################
#                        #
# PROVIDER CONFIGURATION #
#                        #
##########################

# Rather than passing a billion secrets to tofu, we just pass a 1password auth token
# And get the rest of our credentials from 1password. they're exported via the credentials module.
provider "onepassword" {
  service_account_token = var.onepassword_service_account_auth_token
}

provider "digitalocean" {
  token = module.credentials.digitalocean_access_token
}

provider "kubernetes" {
  host                   = module.credentials.kubernetes_host
  token                  = module.credentials.kubernetes_token
  cluster_ca_certificate = module.credentials.kubernetes_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.credentials.kubernetes_host
    token                  = module.credentials.kubernetes_token
    cluster_ca_certificate = module.credentials.kubernetes_cluster_ca_certificate
  }
}

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

# TODO: this fails if the cluster isn't running already...
# https://discuss.hashicorp.com/t/multiple-plan-apply-stages/8320/7


# Once we've got kubernetes up and running, we should configure our providers to target that cluster


# Now we've configured
# 1. Authentication with 1password
# 2. The underlying DOKS cluster
# 3. The k8s and helm providers
#
# Time to spin up some containers!
# Starting with fun stuff like...

# module "chat-server" {
#   source = "./chat-server"

#   providers = {
#     kubernetes = kubernetes.doks
#     helm       = helm.doks
#   }
# }