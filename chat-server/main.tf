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
  name = "matrix-chat"
}


# Create a namespace to logically group everything in.
# All the following resources should be created inside this namespace
resource "kubernetes_namespace" "chat_server" {
  metadata {
    name = local.name
  }
}

locals {
  namespace = kubernetes_namespace.chat_server.metadata[0].name
}

# Configuration for the matrix postgres db
resource "kubernetes_config_map" "postgres_configuration" {
  metadata {
    name      = "pg-config"
    namespace = local.namespace

    labels = {
      app = "postgres"
    }
  }

  data = {
    POSTGRES_DB = "synapse"
    POSTGRES_INITDB_ARGS : "--locale=C --encoding=UTF-8"
  }

}

# Authorization for the matrix postgres db
resource "kubernetes_secret" "postgres_auth" {
  metadata {
    name      = "pg-auth"
    namespace = local.namespace

    labels = {
      app = "postgres"
    }
  }

  data = {
    username = var.pg_user
    password = var.pg_password
  }

  type = "basic-auth"
}

# Persistent volume for postgres db
resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name = "postgres-statefulset"
    namespace = local.namespace

    labels = {
      app = "postgres"
    }
  }

  spec {
    service_name = "postgres"
    replicas = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
  }
}