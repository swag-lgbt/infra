
# Set up postgres for use with synapse.

locals {
  postgres = {
    # Information relating to the pgpass passfile
    passfile = {
      file_name = ".pgpass"

      volume = {
        name       = "pgpass-volume"
        mount_path = "/synapse-pg"
      }
    }

    host     = digitalocean_database_connection_pool.synapse.private_host
    port     = digitalocean_database_connection_pool.synapse.port
    db_name  = digitalocean_database_connection_pool.synapse.db_name
    username = digitalocean_database_user.synapse.name
    password = sensitive(digitalocean_database_user.synapse.password)
  }
}

# Create a database in the cluster
resource "digitalocean_database_db" "synapse" {
  cluster_id = var.postgres.cluster_id
  name       = "synapse"
}

# Create a user to interact with the database
resource "digitalocean_database_user" "synapse" {
  cluster_id = var.postgres.cluster_id
  name       = "synapse"
}

# Create a connection pool that talks to the database
resource "digitalocean_database_connection_pool" "synapse" {
  cluster_id = var.postgres.cluster_id

  name = "synapse"
  mode = "transaction"
  size = var.postgres.connection_pool_size

  db_name = digitalocean_database_db.synapse.name
  user    = digitalocean_database_user.synapse.name
}

# Ok! DigitalOcean config done.
# Now we need to build up a postgres passfile to mount in our container

resource "kubernetes_secret" "passfile" {
  metadata {
    name = "synapse-db-password"
  }

  data = {
    (local.postgres.passfile.file_name) = "${join(":", [
      local.postgres.host,
      local.postgres.port,
      local.postgres.db_name,
      local.postgres.username,
      local.postgres.password
      ]
    )}\n"
  }
}
