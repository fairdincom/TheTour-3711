# Application Insights #

## YAML to JSON Conversion ##

```powershell
./Convert-Templates.ps1
```


## Local Linting ##

```powershell
$RootDirectory = "[ROOT_DIRECTORY]"

& "$RootDirectory/scripts/Lint-Templates.ps1" -RootDirectory $RootDirectory -IsLocal $true
```


## Local Testing ##

1. Login to Azure CLI

    ```bash
    az login
    ```

1. Run the PowerShell script

    ```powershell
    $resourceGroupName = "[RESOURCE_GROUP_NAME]"
    $directory = "./ApplicationInsights"
    $outputFile = "$directory/TestResult.xml"

    $parameters = @{}
    $parameters.ResourceGroupName = $resourceGroupName
    $parameters.SrcDirectory = $directory
    $parameters.IsLocal = $true

    $script = @{}
    $script.Path = $directory
    $script.Parameters = $parameters

    Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml
    ```


## Local Deployment ##

### PowerShell ###

```powershell
New-AzureRmResourceGroupDeployment `
    -Name [DEPLOYMENT_NAME] `
    -ResourceGroupName [RESOURCE_GROUP_NAME] `
    -TemplateFile ./azuredeploy.json `
    -TemplateParameterFile ./azuredeploy.parameters.json `
    -Verbose
```

### Azure CLI ###

```bash
az group deployment create `
    --name [DEPLOYMENT_NAME] `
    --resource-group [RESOURCE_GROUP_NAME] `
    --template-file ./azuredeploy.json `
    --parameters `@azuredeploy.parameters.json `
    --verbose
```
