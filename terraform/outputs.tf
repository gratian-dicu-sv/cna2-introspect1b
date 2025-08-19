output "product_service_url" {
  description = "The URL of the Product Service."
  value       = "https://${azurerm_container_app.product_service.latest_revision_fqdn}"
}

output "order_service_url" {
  description = "The URL of the Order Service."
  value       = "https://${azurerm_container_app.order_service.latest_revision_fqdn}"
}

output "ai_foundry_id" {
  description = "The ID of the Azure AI Foundry."
  value       = var.deploy_ai_foundry ? azapi_resource.ai_foundry[0].id : "Not deployed"
}

output "ai_project_id" {
  description = "The ID of the Azure AI Foundry Project."
  value       = var.deploy_ai_foundry ? azapi_resource.ai_project[0].id : "Not deployed"
}

output "acr_name" {
  description = "The name of the Azure Container Registry."
  value       = azurerm_container_registry.dapr_acr.name
}
