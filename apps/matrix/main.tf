terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}


locals {
  synapse = {
    container = {
      name = "synapse"
    }

    data = {
      volume = {
        name       = "synapse-data-volume"
        mount_path = "/synapse-data"
      }
    }

    # Information relating to the synapse configuration file
    config = {
      # Name of the configuration file (on disk)
      file_name = "homeserver.yaml"

      volume = {
        # Name of the volume created from the above ConfigMap
        name = "synapse-config-volume"

        # Directory in which to mount the above volume in the container
        mount_path = "/synapse-config"
      }
    }
  }
}


resource "kubernetes_stateful_set" "matrix" {
  metadata {
    name = "matrix-stateful-set"
  }

  spec {
    selector {
      match_labels = {
        app = "matrix"
      }
    }

    service_name = "matrix-server"
    replicas     = 1

    template {
      metadata {
        labels = {
          app = "matrix"
        }
        annotations = {
          (var.secrets_injector.annotation) = join(", ", [local.synapse.container.name])
        }
      }

      spec {
        container {
          name  = local.synapse.container.name
          image = "matrixdotorg/synapse:v${var.matrix.synapse_version}"

          # Normally you wouldn't need to do this, but it makes the secret injector work
          command = ["python3"]

          env {
            name = var.secrets_injector.env_var_name
            value_from {
              secret_key_ref {
                name = var.secrets_injector.secret_key_ref.name
                key  = var.secrets_injector.secret_key_ref.key
              }
            }
          }

          env {
            name  = "SYNAPSE_CONFIG_PATH"
            value = "${local.synapse.config.volume.mount_path}/${local.synapse.config.file_name}"
          }

          # Mount /data volume
          volume_mount {
            name       = local.synapse.data.volume.name
            mount_path = local.synapse.data.volume.mount_path
          }

          # Mount homeserver.yaml
          volume_mount {
            name       = local.synapse.config.volume.name
            mount_path = local.synapse.config.volume.mount_path
          }

          # Mount .pgpass file
          volume_mount {
            name       = local.postgres.passfile.volume.name
            mount_path = local.postgres.passfile.volume.mount_path
          }


          port {
            container_port = 8008 # boob lol
          }
        }

        volume {
          name = local.synapse.config.volume.name
          config_map {
            name = kubernetes_config_map.synapse_configuration.metadata[0].name
          }
        }

        volume {
          name = local.postgres.passfile.volume.name
          secret {
            secret_name = kubernetes_secret.passfile.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = local.synapse.data.volume.name
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "${var.matrix.data_volume_size_gib}Gi"
          }
        }

        storage_class_name = "do-block-storage"
      }
    }
  }
}
