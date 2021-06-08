param(
	$config
	,$domain
	)
Write-Log "Configureing the certgetter"
$out = @()
foreach ($d in $config.Domains){
	$out += $d.Records | Select hosts,name,uid,gid,signingProfile
}

$data = $out | ConvertTo-Json -depth 5 

set-content -Value $data -Path "$(Split-Path $PSScriptRoot -Parent)\mountPoints\certgetter\certrequests.json"