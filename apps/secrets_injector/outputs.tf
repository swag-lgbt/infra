output "secret_key_ref" {
  value = {
    name = local.kubernetes_secret_name
    key  = local.kubernetes_secret_key
  }
}

output "annotation" {
  value = "operator.1password.io/inject"
}

output "env_var_name" {
  value = "OP_SERVICE_ACCOUNT_TOKEN"
}
