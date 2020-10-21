$body = '{
	"request": {
		"hosts": [
			"ImageRegistry",
			"localhost",
			"127.0.0.1"
		],
		"names": [
			{
				"C": "Country",
				"ST": "State",
				"L": "City"
			}
		],
		"CN": "ImageRegistry"
	}
}'
$result = $null

$result = Invoke-RestMethod -Method Post -Uri http://ca:8888/api/v1/cfssl/newcert -Body $body -ContentType Application/JSON

if([string]::IsNullOrEmpty($result)){
    Write-Error "Did not get a response from server" -ErrorAction Stop
}

if ($result.success -ne "True"){
    Write-Error "response completed, but CFSSL reports failure" -ErrorAction Stop
}

Write-Host "Getting cert request from response"
$cert = $result.result | select-object certificate_request


Write-Host "Creating cert.key file from response"
$result.result.private_key | Out-File cert.key

$body = $($cert | ConvertTo-Json)
#$body = $($body | ConvertFrom-Json) | select *,@{Name="Bundle";Expression={$true}} | ConvertTo-Json # Not sure if there is a need to bundle, I get an error when I do
$result = $null
$result = Invoke-RestMethod -Method Post -Uri http://ca:8888/api/v1/cfssl/sign -Body $body -ContentType Application/JSON
$result | fl 
Write-Host "Creating cert.crt file from signing response"
$result.result.certificate | Out-File cert.crt

Get-ChildItem /work
Copy-Item -Path /work/cert.crt -Destination /certs/cert.crt
Copy-Item -Path /work/cert.key -Destination /certs/cert.key 

tail -f /dev/null