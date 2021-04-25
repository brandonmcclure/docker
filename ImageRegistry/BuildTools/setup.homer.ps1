param($config)

Import-Module powershell-yaml

$services = @()

foreach ($service in $config.Records){
	$serviceObj = New-Object PSObject -Property @{
		name=$service.Name
		logo="assets/tools/sample.png"
		subtitle=$service.Name
		tag="app"
		url="https://$($service.name).$($config.domain)"
	}
	$services += $serviceObj
}

$servicesWhole = New-Object PSObject -Property @{
	items=$services
}

$configObj = new-object PSObject -Property @{
	title="Brandon's Dashboard"
	subtitle="Homer"
	logo= "logo.png"
	header="true"
	footer='<p>Created with <span class="has-text-danger">❤️</span> with <a href="https://bulma.io/">bulma</a>, <a href="https://vuejs.org/">vuejs</a> & <a href="https://fontawesome.com/">font awesome</a> // Fork me on <a href="https://github.com/bastienwirtz/homer"><i class="fab fa-github-alt"></i></a></p>'
	theme="default"
	services=$servicesWhole

}

$outputPath = "$(Split-Path $PSScriptRoot -Parent)\mountPoints\homer\assets\config.yml"
 ConvertTo-Yaml -data $configObj | Set-Content $outputPath -Force