#!/usr/bin/env bash

set -euxo pipefail

pushd deployments/infrastructure
    terraform init
    terraform apply -auto-approve -refresh=false
    terraform output > ../workspace/infrastructure.auto.tfvars
    databricks_workspace_host=$(terraform output -raw databricks_workspace_host)
popd

export TF_VAR_databricks_cli_profile=adbobs_cli_profile

az account show --query user || az login

# AzureDatabricks
set +x
    token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken -o tsv)
    env DATABRICKS_AAD_TOKEN="$token" databricks configure --aad-token --profile "$TF_VAR_databricks_cli_profile" --host "$databricks_workspace_host"
set -x

pushd deployments/workspace
    terraform init
    terraform apply -auto-approve -refresh=false
popd