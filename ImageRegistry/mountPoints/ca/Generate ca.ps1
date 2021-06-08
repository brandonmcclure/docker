param($domain = "example.com")
Set-Location $PSScriptRoot

openssl genrsa -des3 -out docker_encrypted.key 2048
openssl req -x509 -new -nodes -key ./docker_encrypted.key -sha256 -days 1825 -out docker.crt -subj "/C=US/ST=State/L=City/O=Org/OU=Department/CN=*.$domain"

copy-item ./docker.crt ./ca-bundle.crt

openssl rsa -in ./docker_encrypted.key  -out ./docker.key