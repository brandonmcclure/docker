param($siteName,$adminusername, $adminemail)
$origLoc = Get-Location 

. "$PSScriptRoot\Functions.ps1"

try{
	set-location (split-Path $PSScriptRoot -Parent)
Remove-Item moodle.env -Force -errorAction Ignore
"MOODLE_SITE_NAME=$siteName
MOODLE_DATABASE_HOST=mariadb
MOODLE_DATABASE_PORT_NUMBER=3306
MOODLE_DATABASE_USER=bn_moodle
MOODLE_DATABASE_NAME=bitnami_moodle
ALLOW_EMPTY_PASSWORD=yes
MOODLE_USERNAME=$adminusername
MOODLE_PASSWORD=$(generatePassword | ConvertFrom-SecureString -AsPlainText)
MOODLE_EMAIL=$adminemail
MARIADB_USER=bn_moodle
MARIADB_DATABASE=bitnami_moodle
MARIADB_CHARACTER_SET=utf8mb4
MARIADB_COLLATE=utf8mb4_unicode_ci
"`
| Add-Content -Path moodle.env
}
catch{throw}
finally{
	Set-Location $origLoc
}