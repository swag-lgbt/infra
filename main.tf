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
  cluster_name = "tf-k8s-swag-lgbt"
}

module "doks-cluster" {
  source         = "./doks-cluster"
  cluster_name   = local.cluster_name
  cluster_region = "nyc3"
  
  k8s_version    = var.k8s_version
  node_size_slug = var.doks_node_slug
  max_nodes      = var.max_k8s_nodes
}

module "kubernetes-config" {
  source = "./kubernetes-config"

  # `cluster_name` and `cluster_id` need to be sourced from the `"doks_cluster"` module,
  # not the main module, so that opentofu can figure out that it needs to provision the cluster
  # before it can put stuff on it
  cluster_name = module.doks-cluster.cluster_name
  cluster_id   = module.doks-cluster.cluster_id

  write_kubeconfig = var.write_kubeconfig
}