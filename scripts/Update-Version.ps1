#
# Update version of each ARM template
#

Param(
    [string]
    [Parameter(Mandatory=$true)]
    $RootDirectory,

    [string]
    [Parameter(Mandatory=$true)]
    [ValidatePattern("^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$")]
    $Version
)

Get-ChildItem -Path $RootDirectory -Recurse -Include azuredeploy.json | ForEach-Object {
    $content = Get-Content -Path $_.FullName | ConvertFrom-Json
    $content.contentVersion = $Version
    ($content | ConvertTo-Json -Depth 100).Replace("\u0026", "&").Replace("\u0027", "'") | Set-Content -Path $_.FullName
}
