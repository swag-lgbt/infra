variable "pg_password" {
  sensitive = true
  type      = string
}

variable "pg_user" {
  default = "synapse-db"
  type    = string
}

variable "pg_capacity" {
  type = string
}