#
# This tests whether the ARM template for Consumption Plan will be properly deployed or not.
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

Describe "Consumption Plan Deployment Tests" {
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
    Context "When Consumption Plan deployed with parameters" {
        $templateName = "ConsumptionPlan"

        $organisation = "Environment Protection Authority Victoria"
        $organisationCode = "EPA"
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
        $consumptionPlanKind = "functionapp"
        $consumptionPlanSkuName = "Y1"
        $consumptionPlanSkuTier = "Dynamic"
        $consumptionPlanSkuSize = "Y1"
        $consumptionPlanSkuFamily = "Y"
        $consumptionPlanSkuCapacity = 1

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
            $expected = "$workload-$platformCode-csplan-$organisationCode-$regionCode-$environmentCode"
            $resource = $result.validatedResources[0]

            $resource.name | Should -Be $expected
        }
    }
}
