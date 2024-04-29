variable "secrets_injector" {
  type = object({
    annotation   = string
    env_var_name = string

    secret_key_ref = object({
      name = string
      key  = string
    })
  })
}

variable "matrix" {
  type = object({
    data_volume_size_gib = number
    synapse_version      = string
    default_room_version = number
  })
}

variable "onepassword_vault_uuid" {
  type = string
}

variable "postgres" {
  type = object({
    cluster_id           = string
    connection_pool_size = number
  })
}

variable "kubernetes" {
  type = object({
    namespace = string
  })
}
