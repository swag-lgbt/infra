variable "onepassword_service_account_token" {
  type      = string
  sensitive = true
}

variable "out_dir" {
  type    = string
  default = "dist"
}
