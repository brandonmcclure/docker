param()

. "$PSScriptRoot\Functions.ps1"

$origLoc = Get-Location 

try{
	set-location (split-Path $PSScriptRoot -Parent)
Remove-Item minio.env -Force -errorAction Ignore
"MINIO_ACCESS_KEY=$(generatePassword | ConvertFrom-SecureString -AsPlainText)
MINIO_SECRET_KEY=$(generatePassword | ConvertFrom-SecureString -AsPlainText)
"`
| Add-Content -Path minio.env
}
catch{throw}
finally{
	Set-Location $origLoc
}