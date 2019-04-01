#
# This converts all YAML templates into JSON templates.
#

Get-Item * -Include *.yaml | ForEach-Object {
    ..\..\bin\yarm-cli\yarm.cmd -i $_.FullName
}
