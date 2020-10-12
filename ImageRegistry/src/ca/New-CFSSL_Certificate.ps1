$body = '{
	"request": {
		"hosts": [
			"ImageRegistry"
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

Write-Host "Creating cert.crt file from response"
$result.result.certificate | Out-File cert.crt


Write-Host "Creating cert.key file from response"
$result.result.private_key | Out-File cert.key
Get-ChildItem /work
Copy-Item -Path /work/cert.crt -Destination /certs/cert.crt
Copy-Item -Path /work/cert.key -Destination /certs/cert.key 

Get-ChildItem /certs