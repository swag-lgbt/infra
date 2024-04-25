output "secret_key_ref" {
  value = {
    secret_key_ref = {
      name = local.kubernetes_secret_name
      key  = local.kubernetes_secret_key
    }
  }
}

output "annotation" {
  value = "operator.1password.io/inject"
}
