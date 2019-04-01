#
# This tests whether the ARM template for Application Insights will be properly deployed or not.
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

Describe "Application Insights Deployment Tests" {
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
    Context "When Application Insights deployed with parameters" {
        $templateName = "ApplicationInsights"

        $organisation = "Environment Protection Authority Victoria"
        $organisationCode = "EPA"
        $department = "IT"
        $departmentCode = "it"
        $platform = "Engineering Platform"
        $platformCode = "engin"
        $workload = "devops"
        $region = "Australia East"
        $regionCode = "nsw"
        $location = ""
        $environment = "Development"
        $environmentCode = "dev"
        $resourceInstance = ""
        $workflowName = ""
        $costCenter = "it"
        $accountCode = "NOT_SET"
        $projectName = "NOT_SET"
        $projectCode = "NOT_SET"
        $application = "appins"
        $applicationOwner = "NOT_SET"
        $serviceNowCi = "appins"
        $networkTier = "shared"
        $supportTeam = "NOT_SET"
        $schedule = "24x7"
        $appInsightsKind = "web"

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
            $expected = "$departmentCode-$workload-$platformCode-appins-$organisationCode-$regionCode-$environmentCode".ToLowerInvariant() + `
                        $(if([string]::IsNullOrWhiteSpace($workflowName)) { $workflowName } else { "-$workflowName" })
            $resource = $result.validatedResources[0]

            $resource.name | Should -Be $expected
        }

        It "Should be the expected kind" {
            $expected = $appInsightsKind
            $resource = $result.validatedResources[0]

            $resource.kind | Should -Be $expected
        }

        It "Should be the expected location deployed" {
            $expected = "australiaeast"
            $resource = $result.validatedResources[0]

            $resource.location | Should -Be $expected
        }
    }
}
