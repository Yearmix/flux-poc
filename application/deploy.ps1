param(
    [string]$subscription = "",
    [string]$location = "North Europe",
    [string]$rg_name = "k8s-test-app",
    [string]$acr_name = "olpotestacr",
    [string]$image = "application-test-image"
)

az login
az account set --subscription $subscription

$rg = (az group create --name $rg_name --location $location --tags cost-center="" legal-unit="" --output json) | ConvertFrom-Json
$rg

$acr = (az acr create --location $location --resource-group $rg_name --name $acr_name --sku Basic --admin-enabled true --tags $rg.tags --output json) | ConvertFrom-Json
$acr

$creds = (az acr credential show --name $acr_name) | ConvertFrom-Json
$creds

$loginServer = ((az acr show --name $acr_name --output json) | ConvertFrom-Json).loginServer
$loginServer

$creds.passwords[0].value | docker login $loginServer -u $creds.username --password-stdin

$img = $acr_name + "/" + $image
docker build -t $img .

$acrImagePath = $loginServer + "/" + $img + ":" + "latest"
docker tag $img $acrImagePath

docker push $acrImagePath

$acrImagePath
$img