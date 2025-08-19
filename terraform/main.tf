terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.40.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.6"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "dapr_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "dapr_logs" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.dapr_rg.location
  resource_group_name = azurerm_resource_group.dapr_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "dapr_env" {
  name                       = var.container_apps_environment_name
  location                   = azurerm_resource_group.dapr_rg.location
  resource_group_name        = azurerm_resource_group.dapr_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.dapr_logs.id
}

locals {
  acr_name = var.acr_name == null ? "dapracr${random_string.suffix.result}" : var.acr_name
}

resource "azurerm_container_registry" "dapr_acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.dapr_rg.name
  location            = azurerm_resource_group.dapr_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app" "redis" {
  name                         = "redis"
  container_app_environment_id = azurerm_container_app_environment.dapr_env.id
  resource_group_name          = azurerm_resource_group.dapr_rg.name
  revision_mode                = "Single"

  ingress {
    external_enabled = false
    target_port      = 6379
    transport        = "tcp"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "redis"
      image  = "redis:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}

resource "azurerm_container_app_environment_dapr_component" "pubsub" {
  name                         = "product-pubsub"
  container_app_environment_id = azurerm_container_app_environment.dapr_env.id
  component_type               = "pubsub.redis"
  version                      = "v1"

  metadata {
    name  = "redisHost"
    value = "redis:6379"
  }
}

resource "azurerm_container_app" "product_service" {
  name                         = var.product_service_name
  container_app_environment_id = azurerm_container_app_environment.dapr_env.id
  resource_group_name          = azurerm_resource_group.dapr_rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = var.product_service_name
      image  = "${azurerm_container_registry.dapr_acr.login_server}/${var.product_service_name}:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }

    min_replicas = 1
    max_replicas = 5
    http_scale_rule {
      name = "http-concurrency-rule"
      concurrent_requests = 90
    }
  }

  dapr {
    app_id   = var.product_service_name
    app_port = 3000
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "http"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.dapr_acr.admin_password
  }

  registry {
    server               = azurerm_container_registry.dapr_acr.login_server
    username             = azurerm_container_registry.dapr_acr.admin_username
    password_secret_name = "acr-password"
  }
}

resource "azurerm_container_app" "order_service" {
  name                         = var.order_service_name
  container_app_environment_id = azurerm_container_app_environment.dapr_env.id
  resource_group_name          = azurerm_resource_group.dapr_rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = var.order_service_name
      image  = "${azurerm_container_registry.dapr_acr.login_server}/${var.order_service_name}:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas = 1
    max_replicas = 5
    http_scale_rule {
      name = "http-concurrency-rule"
      concurrent_requests = 90
    }
  }

  dapr {
    app_id   = var.order_service_name
    app_port = 3001
  }

  ingress {
    external_enabled = true
    target_port      = 3001
    transport        = "http"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.dapr_acr.admin_password
  }

  registry {
    server               = azurerm_container_registry.dapr_acr.login_server
    username             = azurerm_container_registry.dapr_acr.admin_username
    password_secret_name = "acr-password"
  }
}

resource "azapi_resource" "ai_foundry" {
  count     = var.deploy_ai_foundry ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  name      = var.ai_foundry_name
  location  = azurerm_resource_group.dapr_rg.location
  parent_id = azurerm_resource_group.dapr_rg.id

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      disableLocalAuth      = false
      allowProjectManagement = true
      customSubDomainName   = var.ai_foundry_name
    }
  }
}

resource "azapi_resource" "ai_project" {
  count     = var.deploy_ai_foundry ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  name      = var.ai_project_name
  location  = azurerm_resource_group.dapr_rg.location
  parent_id = azapi_resource.ai_foundry[0].id

  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      displayName = var.ai_project_name
      description = "AI project for the Dapr application"
    }
  }
}

data "azurerm_client_config" "current" {}
