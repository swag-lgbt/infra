output "credentials" {
  value = {
    digitalocean_access_token         = data.onepassword_item.digitalocean_access_token.password
    cloudflare_api_token              = data.onepassword_item.cloudflare_api_token.password
    onepassword_service_account_token = data.onepassword_item.onepassword_service_account_token.password
  }
  sensitive = true
}

output "vault_uuid" {
  value     = data.onepassword_vault.swag_lgbt.uuid
  sensitive = true
}
