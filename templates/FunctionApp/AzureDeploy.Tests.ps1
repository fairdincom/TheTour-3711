#
# This tests whether the ARM template for Function App will be properly deployed or not.
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

Describe "Function App Deployment Tests" {
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
    Context "When Function App deployed with parameters" {
        $templateName = "FunctionApp"

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
        $workflowName = "test"
        $resourceInstance = ""
        $workflowName = ""
        $costCenter = "it"
        $accountCode = "NOT_SET"
        $projectName = "NOT_SET"
        $projectCode = "NOT_SET"
        $application = "fncapp"
        $applicationOwner = "NOT_SET"
        $serviceNowCi = "fncapp"
        $networkTier = "shared"
        $supportTeam = "NOT_SET"
        $schedule = "24x7"
        $appInsightsRegionCode = "nsw"
        $functionAppKind = "functionapp"
        $functionAppSecretStorageType = "Files"
        $functionAppWorkerRuntime = "dotnet"
        $functionAppExtensionVersion = "~2"
        $functionAppEditMode = "readonly"

        $output = az group deployment validate `
            -g $ResourceGroupName `
            --template-file $RootDirectory\$templateName\azuredeploy.json `
            --parameters `@$RootDirectory\$templateName\azuredeploy.parameters.json `
            | ConvertFrom-Json
        
        $result = $output.properties

        It "Should be deployed successfully" {
            $result.provisioningState | Should -Be "Succeeded"
        }

        It "Should be the expected name" {
            $expected = "$departmentCode-$workload-$platformCode-fncapp-$organisationCode-$regionCode-$environmentCode".ToLowerInvariant() + `
                        $(if([string]::IsNullOrWhiteSpace($workflowName)) { $workflowName } else { "-$workflowName" })
            $resource = $result.validatedResources[0]

            $resource.name | Should -Be $expected
        }
    }
}
