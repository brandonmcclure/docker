param(
	$config
	,$domain
	)
$config.Records | Select hosts,name,uid,gid,signingProfile
$out | ConvertTo-Json -depth 5 | set-content $PSScriptRoot\test.json