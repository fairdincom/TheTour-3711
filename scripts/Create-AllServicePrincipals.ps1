#
# Creates a service principal in bulk
#

param
(
	[Array]
	[Parameter(Mandatory=$true, HelpMessage="Provide an array containing the list of platform codes. eg) data, digital, engin, integ, etc")]
	$platformNames,

	[Array]
	[Parameter(Mandatory=$true, HelpMessage="Provide an array containing environment codes. eg) prd, nprd")]
	$environmentCodes,

	[bool]
	[Parameter(Mandatory=$false, HelpMessage="Provide a value indicating whether to create it for Azure DevOps or not. Default value is 'true'")]
	$createDevOps = $true,

	[bool]
	[Parameter(Mandatory=$false, HelpMessage="Provide a value indicating whether to create it for Key Vault or not. Default value is 'false'")]
	$createKeyVault = $false,

	[bool]
	[Parameter(Mandatory=$false, HelpMessage="Provide a value indicating whether to provide a login or not. Default value is 'true'")]
	$requiredLogin = $true
)

$platformNames | ForEach-Object {
	$platformName = $_
	$environmentCodes | ForEach-Object {
		$environmentCode = $_
		
		$subscriptionName = "it-$platformName-$environmentCode-subscription"

        Write-Host ""
        Write-Host "Chaning Azure Subscription to $subscriptionName..."
        Select-AzureRmSubscription -Subscription $subscriptionName

        # Only runs if Azure DevOps service principal is specified
        if ($createDevOps -eq $true) {
            Write-Host "Creating a Service Principal for Azure DevOps..."

            .\Create-ServicePrincipal.ps1 `
			-subscriptionName $subscriptionName `
			-servicePrincipalName "devops-$platformName-svcpn-epa-$environmentCode-devopsowner" `
			-servicePrincipalRole "owner" `
			-requiredLogin $false
        }

        # Only runs if Azure Key Vault service principal is specified
		if ($createKeyVault -eq $true) {
            Write-Host "Creating a Service Principal for Azure Key Vault..."

            .\Create-ServicePrincipal.ps1 `
			-subscriptionName $subscriptionName `
			-servicePrincipalName "devops-$platformName-svcpn-epa-$environmentCode-keyvaultreader" `
			-servicePrincipalRole "reader" `
			-resourceGroup "it-kv-$platformName-rg-epa-vic-$environmentCode" `
			-resourceType "Microsoft.KeyVault/vaults" `
			-resourceName $($platformName + "kvepavic" + $environmentCode) `
			-requiredLogin $false
        }
	}
}
