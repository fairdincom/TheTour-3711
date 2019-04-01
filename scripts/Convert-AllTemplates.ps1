#
# This converts all YAML templates into JSON templates.
#

Param(
    [string] [Parameter(Mandatory=$true)] $RootDirectory
)

Get-ChildItem * -Include *.yaml | ForEach-Object {
    ..\bin\yarm-cli\yarm.cmd -i $_.FullName
}


$directory = $RootDirectory
$yarmpath = "$RootDirectory\..\bin\yarm-cli\yarm.cmd"

Get-ChildItem -Path $directory -Recurse -Include *.yaml | ForEach-Object {
    & $yarmpath -i $_.FullName -o $($_.FullName).Replace(".yaml", ".json")
}