FROM mcr.microsoft.com/powershell:lts-alpine-3.10
RUN apk update --no-cache
WORKDIR /work
COPY New-CFSSL_Certificate.ps1 /work/New-CFSSL_Certificate.ps1

ENTRYPOINT ["pwsh", "/work/New-CFSSL_Certificate.ps1"]