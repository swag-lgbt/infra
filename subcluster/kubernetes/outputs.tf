output "primary_cluster" {
  value = {
    id   = digitalocean_kubernetes_cluster.primary.id
    name = digitalocean_kubernetes_cluster.primary.name
  }
}

output "monitoring_cluster" {
  value = {
    id   = digitalocean_kubernetes_cluster.monitoring.id
    name = digitalocean_kubernetes_cluster.monitoring.name
  }
}
