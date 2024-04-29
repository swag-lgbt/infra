
# Set up postgres for use with synapse.

locals {
  # Information relating to the pgpass passfile
  passfile = {
    file_name = ".pgpass"

    volume = {
      name       = "pgpass-volume"
      mount_path = "/synapse-pg"
    }
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
# Let's stick these values in some locals so we can easily reference them.

locals {
  pg_host     = digitalocean_database_connection_pool.synapse.private_host
  pg_port     = digitalocean_database_connection_pool.synapse.port
  pg_db_name  = digitalocean_database_connection_pool.synapse.db_name
  pg_username = digitalocean_database_user.synapse.name
  pg_password = sensitive(digitalocean_database_user.synapse.password)
}

# Now we need to build up a postgres passfile to mount in our container

resource "kubernetes_secret" "passfile" {
  metadata {
    name = "synapse-db-password"
  }

  data = {
    (local.passfile.file_name) = "${join(":", [
      local.pg_host,
      local.pg_port,
      local.pg_db_name,
      local.pg_username,
      local.pg_password
      ]
    )}\n"
  }
}
