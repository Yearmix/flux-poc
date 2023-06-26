param(
    [string]$subscription = ""
)

az login
az account set --subscription $subscription

terraform init
terraform apply -auto-approve