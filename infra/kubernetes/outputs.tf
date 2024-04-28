output "host" {
  value = resource.digitalocean_kubernetes_cluster.main.endpoint

  sensitive = true
}

output "token" {
  value = resource.digitalocean_kubernetes_cluster.main.kube_config[0].token

  sensitive = true
}

output "cluster_ca_certificate" {
  value = base64decode(
    resource.digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  )

  sensitive = true
}

output "id" {
  value = resource.digitalocean_kubernetes_cluster.main.id
}
