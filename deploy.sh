#!/bin/bash

# Exit on error
set -e

# --- Azure Login ---
echo "Logging in to Azure..."
az login

echo "Registering required Azure providers..."
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

# --- Terraform ---
echo "Initializing Terraform..."
cd terraform
terraform init

echo "Deploying ACR..."
terraform apply -target=azurerm_container_registry.dapr_acr -auto-approve

ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

echo "ACR Name: $ACR_NAME"
echo "ACR Login Server: $ACR_LOGIN_SERVER"

# --- Docker ---
echo "Logging in to ACR..."
az acr login --name $ACR_NAME

cd .. # Back to root

echo "Building ProductService image for AMD64..."
docker buildx build --platform linux/amd64 -t $ACR_LOGIN_SERVER/product-service:latest --push ./services/ProductService

echo "Building OrderService image for AMD64..."
docker buildx build --platform linux/amd64 -t $ACR_LOGIN_SERVER/order-service:latest --push ./services/OrderService

# --- Deploy remaining infrastructure ---
echo "Deploying the rest of the infrastructure..."
cd terraform
terraform apply -auto-approve

echo "Deployment complete!"

PRODUCT_SERVICE_URL=$(terraform output -raw product_service_url)
ORDER_SERVICE_URL=$(terraform output -raw order_service_url)

echo "Product Service URL: $PRODUCT_SERVICE_URL"
echo "Order Service URL: $ORDER_SERVICE_URL"
