output "digitalocean" {
  value = {
    token = data.onepassword_item.digitalocean_access_token.password
  }
  sensitive   = true
  description = "Credentials for interacting with DigitalOcean resources"
}

output "kubernetes" {
  value = {
    host  = data.digitalocean_kubernetes_cluster.primary.endpoint
    token = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
    )
  }
  sensitive = true
}

