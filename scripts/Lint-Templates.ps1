#
# This invokes linter run.
#

Param(
    [string] [Parameter(Mandatory=$true)] $RootDirectory,
    [bool] [Parameter(Mandatory=$false)] $IsLocal = $false
)

# Defines the list of required files. These files MUST exists in all ARM template directories.
$files = @(
    "azuredeploy.json"
    "azuredeploy.lints.json"
    "azuredeploy.parameters.json"
    "AzureDeploy.Tests.ps1"
    "README.md"
)

$result = @()

# Gets all ARM template directories
Get-ChildItem -Path $RootDirectory -Directory -Exclude bin,outputs,scripts | ForEach-Object {
    $items = Get-Item $($_.FullName + "\*") -Include $files | Sort-Object -Property @{ Expression = "Name"; Descending = $false }

    # Any empty directory is considered as "passed"
    if (($items -eq $null) -or ($items.Count -eq 0)) {
        $result += $true
    }
    # If the number of items in a directory is not equivalent to the expectation, the linting process fails
    elseif ($items.Count -ne $files.Count) {
        $result += $false
    }
    # Lint the directories only not empty
    else {
        $parameters = @()

        # azuredeploy.json
        $template = Get-Content $items[0] | ConvertFrom-Json
        $template.parameters.PSObject.Properties | ForEach-Object {
            $parameters += $_.Name
        }
        
        # azuredeploy.lints.json
        $lints = Get-Content $items[1] | ConvertFrom-Json

        # ARM template parameters SHOULD contain all parameters defined in azuredeploy.lints.json        
        $notcontains = @()
        $lints.parameters | ForEach-Object {
            if ($parameters -notcontains $_) {
                $notcontains += $true
            }
        }

        $result += $notcontains.Count -eq 0

        # Gets all resources other than Logic App
        $resources = $template.resources | Where-Object { $_.type -ne "Microsoft.Logic/workflows" }
        $json = (ConvertTo-Json $resources).Replace("\u0027", "'")

        # ARM template resources SHOULD NOT contain any strings defined in azuredeploy.lints.json
        $notcontains = @()
        $lints.resources | ForEach-Object {
            if ($json -like $("*" + $_ + "*")) {
                $notcontains += $true
            }
        }
        
        $result += $notcontains.Count -eq 0
    }
}

$notpassed = $result | Where-Object { $_ -eq $false }

if ($notpassed.Count -eq 0) {
    Write-Host "Lint Passed" -ForegroundColor Green
} else {
    Write-Host "Lint Failed" -ForegroundColor Red -BackgroundColor Yellow

    if ($IsLocal -eq $false) {
        throw "Lint Failed"
    }
}
