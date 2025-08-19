variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "dapr-rg"
}

variable "location" {
  description = "The Azure region to deploy the resources."
  type        = string
  default     = "East US"
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace."
  type        = string
  default     = "dapr-logs"
}

variable "container_apps_environment_name" {
  description = "The name of the Container Apps environment."
  type        = string
  default     = "dapr-env"
}

variable "acr_name" {
  description = "The name of the Azure Container Registry."
  type        = string
  default     = "gddapracr"
}

variable "product_service_name" {
  description = "The name of the Product Service Container App."
  type        = string
  default     = "product-service"
}

variable "order_service_name" {
  description = "The name of the Order Service Container App."
  type        = string
  default     = "order-service"
}
