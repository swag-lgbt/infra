output "digitalocean_access_token" {
  value = data.onepassword_item.digitalocean_access_token.password
  sensitive = true
  description = "The personal access token for interacting with DigitalOcean resources"
}

