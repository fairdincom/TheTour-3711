#
# Creates a service principal
#

param
(
    [Parameter(Mandatory=$true, HelpMessage="Enter Azure Subscription name. You need to be Subscription Admin to execute the script")]
    [string] $subscriptionName,

    [Parameter(Mandatory=$true, HelpMessage="Provide a name for the Service Principal")]
    [string] $servicePrincipalName,

    [Parameter(Mandatory=$false, HelpMessage="Provide a role assignment for Service Principal. Possible value can be either 'owner' or 'reader'")]
    [ValidatePattern("(owner|reader)")]
    [string] $servicePrincipalRole = "reader",

    [Parameter(Mandatory=$false, HelpMessage="Provide a resource group name for Service Principal to be scoped")]
    [string] $resourceGroup = $null,

    [Parameter(Mandatory=$false, HelpMessage="Provide a resource type for Service Principal to be scoped")]
    [string] $resourceType = $null,

    [Parameter(Mandatory=$false, HelpMessage="Provide a resource name for Service Principal to be scoped")]
    [string] $resourceName = $null,

    [Parameter(Mandatory=$false, HelpMessage="Provide a value indicating whether to provide a login or not. Default value is 'true'")]
    [bool] $requiredLogin = $true
)

#Initialize
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$pwGuid = [guid]::NewGuid()
$pwBytes = [System.Text.Encoding]::UTF8.GetBytes($pwGuid)
$password = [System.Convert]::ToBase64String($pwBytes)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$homePage = "https://" + $servicePrincipalName.replace(' ', '')
$identifierUri = $homePage


#Initialize subscription
$isAzureModulePresent = Get-Module -Name AzureRM* -ListAvailable
if ([String]::IsNullOrEmpty($isAzureModulePresent) -eq $true)
{
    Write-Output "Script requires AzureRM modules to be present. Obtain AzureRM from https://github.com/Azure/azure-powershell/releases. Please refer https://github.com/Microsoft/vsts-tasks/blob/master/Tasks/DeployAzureResourceGroup/README.md for recommended AzureRM versions." -Verbose
    return
}

Import-Module -Name AzureRM.Profile
if ($requiredLogin -eq $true) {
    Write-Output "Provide your credentials to access Azure subscription $subscriptionName" -Verbose
    Login-AzureRmAccount -SubscriptionName $subscriptionName
}

$azureSubscription = Get-AzureRmSubscription -SubscriptionName $subscriptionName
$connectionName = $azureSubscription.SubscriptionName
$tenantId = $azureSubscription.TenantId
$id = $azureSubscription.SubscriptionId

#Create a new AD Application
Write-Output "Creating a new Application in AAD (App URI - $identifierUri)" -Verbose
$azureAdApplication = New-AzureRmADApplication -DisplayName $servicePrincipalName -HomePage $homePage -IdentifierUris $identifierUri -Password $securePassword -Verbose
$appId = $azureAdApplication.ApplicationId
Write-Output "Azure AAD Application creation completed successfully (Application Id: $appId)" -Verbose

#Create new SPN
Write-Output "Creating a new SPN" -Verbose
$spn = New-AzureRmADServicePrincipal -ApplicationId $appId
$objectId = $spn.Id
$spnName = $spn.ServicePrincipalNames[1]
Write-Output "SPN creation completed successfully (SPN Name: $spnName)" -Verbose

#Assign role to SPN
Write-Output "Waiting for SPN creation to reflect in Directory before Role assignment"
Start-Sleep 20
Write-Output "Assigning role ($servicePrincipalRole) to SPN App ($appId)" -Verbose
if (([string]::IsNullOrWhiteSpace($resourceGroup) -eq $false) -and ([string]::IsNullOrWhiteSpace($resourceType) -eq $false) -and ([string]::IsNullOrWhiteSpace($resourceName) -eq $false)) {
    Write-Output "Resource Group: $resourceGroup"
    Write-Output "Resource Type: $resourceType"
    Write-Output "Resource Name: $resourceName"

    New-AzureRmRoleAssignment -RoleDefinitionName $servicePrincipalRole -ServicePrincipalName $appId -ResourceGroupName $resourceGroup -ResourceType $resourceType -ResourceName $resourceName
} elseif (([string]::IsNullOrWhiteSpace($resourceGroup) -eq $false) -and ([string]::IsNullOrWhiteSpace($resourceType) -eq $false)) {
    Write-Output "Resource Group: $resourceGroup"
    Write-Output "Resource Type: $resourceType"

    New-AzureRmRoleAssignment -RoleDefinitionName $servicePrincipalRole -ServicePrincipalName $appId -ResourceGroupName $resourceGroup -ResourceType $resourceType
} elseif ([string]::IsNullOrWhiteSpace($resourceGroup) -eq $false) {
    Write-Output "Resource Group: $resourceGroup"

    New-AzureRmRoleAssignment -RoleDefinitionName $servicePrincipalRole -ServicePrincipalName $appId -ResourceGroupName $resourceGroup
} else {
    New-AzureRmRoleAssignment -RoleDefinitionName $servicePrincipalRole -ServicePrincipalName $appId
}
Write-Output "SPN role assignment completed successfully" -Verbose


#Print the values
Write-Output "`nCopy and Paste below values for Service Connection" -Verbose
Write-Output "***************************************************************************"
Write-Output "Subscription Name: $($azureSubscription.Name)"
Write-Output "Subscription Id: $($azureSubscription.Id)"
Write-Output "Tenant Id: $($azureSubscription.TenantId)"
Write-Output "Service Principal Application Id: $($azureAdApplication.ApplicationId)"
Write-Output "Service Principal Object Id: $($spn.Id)"
Write-Output "App Registration Object Id: $($azureAdApplication.ObjectId)"
Write-Output "Service Principal Key: $password"
Write-Output "Identifier URL: $identifierUri"
Write-Output "Scoped to:"
Write-Output "- Subscription: $($azureSubscription.Name)"
Write-Output "- Resource Group: $(if ([string]::IsNullOrWhiteSpace($resourceGroup)) { "N/A" } else { $resourceGroup })"
Write-Output "- Resource Type: $(if ([string]::IsNullOrWhiteSpace($resourceType)) { "N/A" } else { $resourceType })"
Write-Output "- Resource Name: $(if ([string]::IsNullOrWhiteSpace($resourceName)) { "N/A" } else { $resourceName })"
Write-Output "***************************************************************************"