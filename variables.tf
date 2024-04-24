variable "k8s_version_prefix" {
  default = "1.29"
}

variable "max_k8s_nodes" {
  default = 3
}

variable "doks_node_slug" {
  default = "s-2vcpu-4gb"
}

variable "onepassword_service_account_auth_token" {
  type      = string
  sensitive = true
}

variable "write_kubeconfig" {
  type    = bool
  default = false
}