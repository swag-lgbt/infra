# Configuration for the matrix server.
# https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html

data "onepassword_item" "manhole_credentials" {
  vault = var.onepassword_vault_uuid
  title = "Synapse Manhole Login"
}

locals {
  ports = {
    manhole = 9000
    metrics = 9001
    http    = 9002
  }
}

locals {
  homeserver_yaml = {
    # Server Options
    # https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#server

    server_name            = "swag.lgbt"
    public_baseurl         = "https://matrix.swag.lgbt"
    serve_server_wellknown = true

    require_auth_for_profile_requests = true
    default_room_version              = "${var.matrix.default_room_version}"

    listeners = [
      {
        # https://element-hq.github.io/synapse/latest/manhole.html
        port           = local.ports.manhole,
        bind_addresses = ["0.0.0.0", "::"]
        type           = "manhole"
      },
      {
        # https://element-hq.github.io/synapse/latest/metrics-howto.html#how-to-monitor-synapse-metrics-using-prometheus
        port           = local.ports.metrics
        bind_addresses = ["0.0.0.0", "::"]
        type           = "metrics"
      },
      {
        port           = local.ports.http
        bind_addresses = ["0.0.0.0", "::"]
        type           = "http"

        # TLS termination is handled by kubernetes, and so is routing, so disable TLS and enable X-FORWARDED-FOR
        tls         = false
        x_forwarded = true

        # Cloudflare generates a unique request ID in the `CF-RAY` header, so use it
        request_id_header = "CF-RAY"

        resources = {
          names    = ["client", "consent", "media", "openid"]
          compress = true
        }
      }
    ]

    manhole_settings = {
      username = data.onepassword_item.manhole_credentials.username
      password = data.onepassword_item.manhole_credentials.password
    }

    delete_stale_devices_after = "2w"

    # Homeserver blocking
    # https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#homeserver-blocking
    admin_contact            = "cass@swag.lgbt"
    max_avatar_size          = "10M"
    allowed_avatar_mimetypes = ["image/png", "image/jpeg", "image/gif"]

    # Database
    # https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#database
    database = {
      name      = "psycopg2"
      txn_limit = 1000

      args = {
        # Postgres-specific args
        # https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS
        host = local.postgres.host
        port = local.postgres.port

        dbname   = local.postgres.db_name
        user     = local.postgres.username
        passfile = "${local.postgres.passfile.volume.mount_path}/${local.postgres.passfile.file_name}"

        application_name = "synapse"

        # Connection-pool specific args
        # https://docs.twistedmatrix.com/en/stable/api/twisted.enterprise.adbapi.ConnectionPool.html#__init__
        cp_min = floor(var.postgres.connection_pool_size / 2)
        cp_max = var.postgres.connection_pool_size
      }
    }

    # Logging
    # https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#logging
    # TODO
    # log_config = "path/to/log.config"

    # Media Store
    # https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#media-store
    media_store_path    = "${local.synapse.data.volume.mount_path}/media_store"
    dynamic_thumbnails  = true
    url_preview_enabled = true
    url_preview_ip_range_blacklist = [
      "127.0.0.0/8",
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "100.64.0.0/10",
      "192.0.0.0/24",
      "169.254.0.0/16",
      "192.88.99.0/24",
      "198.18.0.0/15",
      "192.0.2.0/24",
      "198.51.100.0/24",
      "203.0.113.0/24",
      "224.0.0.0/4",
      "::1/128",
      "fe80::/10",
      "fc00::/7",
      "2001:db8::/32",
      "ff00::/8",
      "fec0::/10"
    ]
  }
}

resource "kubernetes_config_map" "synapse_configuration" {
  metadata {
    name = "synapse-config"
  }

  data = {
    (local.synapse.config.file_name) = yamlencode(local.homeserver_yaml)
  }
}
