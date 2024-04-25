# https://developer.1password.com/docs/k8s/k8s-injector/?workflow-type=service-account

terraform {
  required_providers {
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
  kubernetes_secret_name = "1password-service-account"
  kubernetes_secret_key  = "token"
}

resource "kubernetes_secret" "onepassword_service_account_token" {
  metadata {
    name = local.kubernetes_secret_name
  }

  data = { (local.kubernetes_secret_key) = var.onepassword.service_account_token }
}

resource "kubernetes_labels" "secrets_injection_enabled" {
  api_version = "v1"
  kind        = "Namespace"

  metadata {
    name = var.kubernetes.namespace
  }

  labels = {
    "secrets-injection" = "enabled"
  }
}

resource "helm_release" "secrets_injector" {
  name       = "1password-secrets-injector"
  repository = "https://1password.github.io/connect-helm-charts"
  chart      = "secrets-injector"
  version    = "1.0.1"
}
