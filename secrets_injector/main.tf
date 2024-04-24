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

resource "kubernetes_secret" "onepassword_service_account_token" {
  metadata {
    name = "1password-service-account-token"
  }

  data = { token = var.service_account_token }
}

resource "kubernetes_labels" "secrets_injection_enabled" {
  api_version = "v1"
  kind        = "Namespace"

  metadata {
    name = "default"
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
