output "cluster" {
  value = {
    id   = digitalocean_kubernetes_cluster.swag_lgbt.id
    name = digitalocean_kubernetes_cluster.swag_lgbt.name
  }
}


