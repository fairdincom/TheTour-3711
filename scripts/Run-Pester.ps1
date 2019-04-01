#
# This invokes pester test run.
#

Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $RootDirectory,
    [string] [Parameter(Mandatory=$true)] $OutputDirectory,
    [string] [Parameter(Mandatory=$true)] $BuildNumber,
    [hashtable] [Parameter(Mandatory=$false)] $Secrets = $null,
    [string] [Parameter(Mandatory=$false)] $Username = $null,
    [string] [Parameter(Mandatory=$false)] $Password = $null,
    [string] [Parameter(Mandatory=$false)] $TenantId = $null,
    [bool] [Parameter(Mandatory=$false)] $IsLocal = $false
)

$parameters = @{ ResourceGroupName = $ResourceGroupName; RootDirectory = $RootDirectory; Secrets = $Secrets; IsLocal = $true }

$outputFile = "$OutputDirectory\TEST-$BuildNumber.xml"
$script = @{ Path = $RootDirectory; Parameters = $parameters }

if ($IsLocal -eq $true) {
    Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml
} else {
    az login --service-principal -u $Username -p $Password -t $TenantId

    Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml -EnableExit
}
