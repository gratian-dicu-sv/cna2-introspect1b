#!/bin/bash

# Exit on error
set -e

# --- Script Usage ---
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <ResourceGroupName> [Location]"
    echo "Example: $0 my-dapr-rg \"East US\""
    exit 1
fi

RESOURCE_GROUP_NAME=$1
LOCATION=${2:-"East US"} # Default to "East US" if not provided

echo "Deploying AI Foundry to Resource Group: $RESOURCE_GROUP_NAME in $LOCATION"

# --- Azure Login ---
echo "Logging in to Azure..."
az login

echo "Registering Cognitive Services provider..."
az provider register --namespace Microsoft.CognitiveServices --wait

SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# --- Terraform ---
echo "Initializing Terraform..."
cd terraform
terraform init -upgrade

echo "Deploying Azure AI Foundry and related resources..."
terraform apply -var="deploy_ai_foundry=true" \
  -var="subscription_id=$SUBSCRIPTION_ID" \
  -var="resource_group_name=$RESOURCE_GROUP_NAME" \
  -var="location=$LOCATION" \
  -target=azapi_resource.ai_foundry \
  -target=azapi_resource.ai_project \
  -auto-approve

echo "AI Foundry deployment complete!"

AI_FOUNDRY_ID=$(terraform output -raw ai_foundry_id)
AI_PROJECT_ID=$(terraform output -raw ai_project_id)

echo "AI Foundry ID: $AI_FOUNDRY_ID"
echo "AI Project URL: https://ai.azure.com/foundryProject/overview?wsid=/$AI_PROJECT_ID"
