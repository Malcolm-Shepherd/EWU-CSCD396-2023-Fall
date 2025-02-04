﻿$SubscriptionId = "ec5397a2-8944-4e78-b6c4-cbbc5cce0bce"
$ResourceGroup = "CSCD396-Fall"
$WebAppName = "Assignment2-396Fall"
$WebAppUrl = "assignment2-396fall.azurewebsites.net"
$KeyVault = "assignment2-keyvault"
$SecretName = "Assignment2Secret"
$StorageAccount = "cscd396storage"

$RequirementsMet = 0
$TotalRequirements = 10
# az login
Connect-AzAccount -Subscription $SubscriptionId -Tenant "cbb8585a-58be-4c67-a9e8-aa46ea967bb1"
$#Set-AzContext -Subscription $SubscriptionId -Tenant "cbb8585a-58be-4c67-a9e8-aa46ea967bb1"
GraderObjectId = ((Get-AzContext).Account.ExtendedProperties.HomeAccountId.Split('.'))[0]

# Create an Azure AD token for authentication
$token = (Get-AzAccessToken).Token
az account set --subscription $SubscriptionId
az group show -n $ResourceGroup
$WebAppResult = az webapp show -n $WebAppName --resource-group $ResourceGroup --query name -o tsv
if ($WebAppResult) {
    $RequirementsMet++
    Write-Host "Successfully found the Azure Web App through az cli"
}
else {
    Write-Host "Failed to find the Azure Web App through az cli"
}

# Define headers for sending web reqest to the web app, including the Bearer token
$headers = @{
    "Authorization" = "Bearer $token"
}

# Send an HTTP GET request to the Azure Web App URL
$response = Invoke-WebRequest -Uri $WebAppUrl -Headers $headers

# Check the response
if ($response.StatusCode -eq 200) {
    Write-Host "Successfully accessed the Azure Web App URL."
    # You can access the content of the response using $response.Content
    $RequirementsMet++
}
else {
    Write-Host "Failed to access the Azure Web App URL. Status code: $($response.StatusCode)"
    # You can handle errors as needed
}

$Identity = az webapp show -n $WebAppName --resource-group $ResourceGroup --query identity
if ($Identity) {
    $RequirementsMet++
    Write-Host "Successfully found the web app identity through az cli"
}
else {
    Write-Host "Failed to find the web app identity through az cli"
}

$StorageResult = az storage account show --name $StorageAccount --resource-group $ResourceGroup --query name -o tsv
if ($StorageResult) {
    $RequirementsMet++
    Write-Host "Successfully found the storage account through az cli"
}
else {
    Write-Host "Failed to find the storage account through az cli"
}

$spID = $(az resource list -n $WebAppName --query [*].identity.principalId --out tsv)
$storageId = $(az storage account show -n $StorageAccount -g $ResourceGroup --query id --out tsv)

$RoleAssignment = az role assignment list --assignee $spID --scope $storageId --role 'Storage Blob Data Contributor'
if ($RoleAssignment.Count) {
    $RequirementsMet++
    Write-Host "Successfully found web app access to storage account through az cli"
}
else {
    Write-Host "Failed to find web app access to storage account through az cli"
}

$KeyVaultResponse = az keyvault show --name $KeyVault --resource-group $ResourceGroup --query name -o tsv
if ($KeyVaultResponse) {
    $RequirementsMet++
    Write-Host "Successfully found key vault through az cli"
}
else {
    Write-Host "Failed to find key vault through az cli"
}

$Secret = az keyvault secret show --name $SecretName --vault-name $KeyVault --query "value"

if ($Secret) {
    $RequirementsMet++
    Write-Host "Successfully found secret through az cli"
}
else {
    Write-Host "Failed to find secret through az cli"
}

$KeyVaultObject = Get-AzKeyVault -VaultName $KeyVault
$WebAppAccessPolicy = $keyVaultObject.AccessPolicies | Where-Object { $_.ObjectId -match $spID } | Select-Object -ExpandProperty 'PermissionsToSecrets'

if ($WebAppAccessPolicy.Count -gt 1) {
    $WebAppAccessPolicy = $WebAppAccessPolicy | Where-Object { $_ -like 'get' }
}

if ($WebAppAccessPolicy -like 'get') {
    $RequirementsMet++
    Write-Host "Successfully found key vault secrets access policy for web app identity"
}
else {
    Write-Host "Failed to find key vault secrets access policy for web app identity"
}

$GraderAccessPolicy = $keyVaultObject.AccessPolicies | Where-Object { $_.ObjectId -match $GraderObjectId } | Select-Object -ExpandProperty 'PermissionsToSecrets'
if ($GraderAccessPolicy.Count -gt 1) {
    $GraderAccessPolicy = $GraderAccessPolicy | Where-Object { $_ -like 'get' }
}

if ($GraderAccessPolicy -like 'get') {
    $RequirementsMet++
    Write-Host "Successfully found key vault secrets access policy for grader identity"
}
else {
    Write-Host "Failed to find key vault secrets access policy for grader identity"
}

$expectedValue = "@Microsoft.KeyVault(SecretUri=https://$KeyVault.vault.azure.net/secrets/$SecretName/*)"

$appSettingResult = az webapp config appsettings list -n $WebAppName --resource-group $ResourceGroup | ConvertFrom-Json 
$appSettingValue = $appSettingResult | Where-Object { $_.name -like $SecretName } | Select-Object -ExpandProperty value
if ($appSettingValue -like $expectedValue ) {
    $RequirementsMet++
    Write-Host "Successfully found app setting with key vault secret reference"
}
else {
    Write-Host "Failed to find key vault app setting with key vault secret reference"
}

Write-Host "Requirements Met on Assignment $RequirementsMet/$TotalRequirements"