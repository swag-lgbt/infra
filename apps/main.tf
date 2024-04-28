terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = var.kubernetes.namespace
  }
}

module "secrets_injector" {
  source = "./secrets_injector"

  onepassword = var.onepassword

  kubernetes = {
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
}
