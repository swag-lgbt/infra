locals {
  kubernetes_namespace = "default"
}

module "secrets_injector" {
  source = "./secrets_injector"

  onepassword = {
    service_account_token = var.onepassword.service_account_token
  }

  kubernetes = {
    namespace = local.kubernetes_namespace
  }
}
