module "secrets_injector" {
  source = "./secrets_injector"

  onepassword = var.onepassword

  kubernetes = var.kubernetes
}
