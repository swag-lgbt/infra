output "digitalocean_access_token" {
  value       = data.onepassword_item.digitalocean_access_token.password
  sensitive   = true
  description = "The personal access token for interacting with DigitalOcean resources"
}

output "kubernetes_host" {
  value     = data.digitalocean_kubernetes_cluster.primary.endpoint
  sensitive = true
}

output "kubernetes_token" {
  value     = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
  sensitive = true
}

output "kubernetes_cluster_ca_certificate" {
  value = base64decode(
    data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
  )
  sensitive = true
}
