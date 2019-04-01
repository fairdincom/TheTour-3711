#
# This tests whether the ARM template for App Service Stack will be properly deployed or not.
#

Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $RootDirectory,
    [hashtable] [Parameter(Mandatory=$false)] $Secrets = $null,
    [string] [Parameter(Mandatory=$false)] $Username = $null,
    [string] [Parameter(Mandatory=$false)] $Password = $null,
    [string] [Parameter(Mandatory=$false)] $TenantId = $null,
    [bool] [Parameter(Mandatory=$false)] $IsLocal = $false
)

Describe "App Service Stack Deployment Tests" {
    # Init
    BeforeAll {
        if ($IsLocal -eq $false) {
            az login --service-principal -u $Username -p $Password -t $TenantId
        }
    }

    # Teardown
    AfterAll {
    }

    # Tests whether the cmdlet returns value or not.
    Context "When App Service Stack deployed with parameters" {
        $templateName = "stack-appservice"
        $baseTemplateBlobSasToken = $Secrets.BaseTemplateBlobSasToken

        $content = Get-Content $RootDirectory\$templateName\azuredeploy.parameters.json | ConvertFrom-Json
        $content.parameters.baseTemplateBlobSasToken.value = $baseTemplateBlobSasToken
        ($content | ConvertTo-Json -Depth 100).Replace("\u0026", "&").Replace("\u0027", "'") | Out-File $RootDirectory\$templateName\azuredeploy.parameters.sec.json

        $organisation = "Environment Protection Authority Victoria"
        $organisationCode = "EPA"
        $department = "IT"
        $departmentCode = "it"
        $platform = "Engineering Platform"
        $platformCode = "engin"
        $workload = "devops"
        $region = "Australia South-East"
        $regionCode = "vic"
        $location = ""
        $environment = "Development"
        $environmentCode = "dev"
        $resourceInstance = ""
        $costCenter = "it"
        $accountCode = "NOT_SET"
        $projectName = "NOT_SET"
        $projectCode = "NOT_SET"
        $application = "asplan"
        $applicationOwner = "NOT_SET"
        $serviceNowCi = "asplan"
        $networkTier = "shared"
        $supportTeam = "NOT_SET"
        $schedule = "24x7"
        $appInsightsKind = "web"
        $appInsightsRegionCode = "nsw"
        $appServiceKind = "app"
        $appServiceClientAffinityEnabled = $true
        $appServiceHttpsOnly = $true
        $appServiceRemoteDebuggingEnabled = $false
        $appServiceRemoteDebuggingVersion = "VS2017"
        $appServiceUse32bitWorkerProcess = $true
        $appServiceAlwaysOn = $true
        $appServiceFtpsState = "Disabled"
        $appServicePlanKind = "app"
        $appServicePlanSkuName = "S1"
        $appServicePlanSkuTier = "Standard"
        $appServicePlanSkuSize = "S1"
        $appServicePlanSkuFamily = "S"
        $appServicePlanSkuCapacity = 1

        $output = az group deployment validate `
            -g $ResourceGroupName `
            --template-file $RootDirectory\$templateName\azuredeploy.json `
            --parameters `@$RootDirectory\$templateName\azuredeploy.parameters.sec.json `
            | ConvertFrom-Json
        
        $result = $output.properties

        Remove-Item $RootDirectory\$templateName\azuredeploy.parameters.sec.json -Force

        It "Should be deployed successfully" {
            $result.provisioningState | Should -Be "Succeeded"
        }

        It "Should deploy Application Insights" {
            $resource = $result.validatedResources | Where-Object { $_.type -eq "Microsoft.Insights/components" }

            $resource | Should -Not -BeNullOrEmpty

            $expected = "$departmentCode-$workload-$platformCode-appins-$organisationCode-$appInsightsRegionCode-$environmentCode".ToLowerInvariant() + `
                        $(if([string]::IsNullOrWhiteSpace($workflowName)) { $workflowName } else { "-$workflowName" })

            $resource.name | Should -Be $expected
        }

        It "Should deploy App Service Plan" {
            $resource = $result.validatedResources | Where-Object { $_.type -eq "Microsoft.Web/serverfarms" }

            $resource | Should -Not -BeNullOrEmpty

            $expected = "$workload-$platformCode-asplan-$organisationCode-$regionCode-$environmentCode"

            $resource.name | Should -Be $expected
        }

        It "Should deploy App Service" {
            $resource = $result.validatedResources | Where-Object { $_.type -eq "Microsoft.Web/sites" }

            $resource | Should -Not -BeNullOrEmpty

            $expected = "$departmentCode-$workload-$platformCode-webapp-$organisationCode-$regionCode-$environmentCode".ToLowerInvariant() + `
                        $(if([string]::IsNullOrWhiteSpace($workflowName)) { $workflowName } else { "-$workflowName" })

            $resource.name | Should -Be $expected
        }
    }
}
