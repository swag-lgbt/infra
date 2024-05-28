output "preview_deployment_config" {
  value       = cloudflare_pages_project.passport.deployment_configs[0].preview
  description = "Deployment configuration for the preview environment"
}
