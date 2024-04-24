output "host" {
  value = data.digitalocean_kubernetes_cluster.primary.endpoint
}

output "token" {
  value = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
}

output "cluster_ca_certificate" {
  value = base64decode(
    data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
  )
}
