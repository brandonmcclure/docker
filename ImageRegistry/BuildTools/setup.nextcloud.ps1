param($domain="nextcloud.mcd.com")
$origLoc = Get-Location 

try{
	set-location (split-Path $PSScriptRoot -Parent)
Remove-Item nextcloud.env -Force -errorAction Ignore
"NEXTCLOUD_TRUSTED_DOMAINS=$domain
MYSQL_HOST=db
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=nextcloud
NEXTCLOUD_ADMIN_USER=brandon
NEXTCLOUD_ADMIN_PASSWORD=badpassword 
MYSQL_ROOT_PASSWORD=password
"`
| Add-Content -Path nextcloud.env
}
catch{throw}
finally{
	Set-Location $origLoc
}