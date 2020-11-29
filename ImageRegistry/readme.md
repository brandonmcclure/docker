# Synopsis
This started as me setting up a docker registry. It has morphed to include a CA and DNS services. 

This is used for my learning and should not be used by anyone for anything "production" related. Feel free to PR or raise issues if you have any problems though, as I am interested in learning what works and what does not.
docker exec -it registry bin/registry garbage-collect /etc/docker/registry/config.yml
# More detailed description
# Instructions
#
# Set the following environment variables before running/building:
## [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY", "localhost:5000", "Process")
## [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "basicAuth", "Process")
## [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "basicAuth", "Process")
## [Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHUSER", "basicAuth", "Process")
## [Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHPASSWORD", "basicAuth", "Process")
## [Environment]::SetEnvironmentVariable("RESTART_POLICY", "no", "Process") # no, on-failure, always,unless-stopped
## [Environment]::SetEnvironmentVariable("HTTP_PROXY", "", "Process")
##
## Check the values with:
## [Environment]::GetEnvironmentVariable("DOCKER_REGISTRY", "Process")
## [Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "Process")
## [Environment]::GetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "Process")
#
# Notes for trying to get the cfssl to work with my intermeadeate CA
# https://web.archive.org/web/20200718025349/https://propellered.com/posts/cfssl_setting_up/
# https://web.archive.org/web/20200718025350/https://propellered.com/posts/cfssl_setting_up_ocsp_api/
# How to run
## CA/CFSSL
This expects a CA certificate (`docker.crt`) and key (`docker.key`) for signing, and a `ca-bundle.crt` bundle/chain of the signing cert/up to the root CA located at `/mountpoints/ca`

This can self signed by you using openssl, or you can bring your own from a CA/intermeadiate CA. I used an intermeadiate CA that I generated from my Truenas box. My thinking is that this will give me the best client certs because I have the root and int CA trusted on my computers, and if I mess up and need to revoke the intermediate CA that is used for signing my docker certs then I can without messing up the rest of my PKI for my physical machines/freebsd jails.

## CoreDNS
Create a `config/config.json` file that looks something like:
```
{
    "domain":"yourDomain.com",
    "forward":[".","8.8.8.8","9.9.9.9"],
    "Records":[
        {"Name":"yourDomain.com.","ZoneClass":"IN","RecordType":"SOA","MNAME":"dns.yourDomain.com.","RNAME":"theadminemail.yourDomain.com","SERIAL":"2015082541","REFRESH":"7200","RETRY":"3600","EXPIRE":"1209600","TTL":"3600"},
        {"Name":"dns.yourDomain.com.","ZoneClass":"IN","RecordType":"A","IpAddress":"10.0.0.2"},
        {"Name":"ca.yourDomain.com.","ZoneClass":"IN","RecordType":"A","IpAddress":"10.0.0.2"},
        {"Name":"gateway.yourDomain.com.","ZoneClass":"IN","RecordType":"A","IpAddress":"10.0.0.1"},
    ]
}
```
Make sure you update the `forward` section with your dns servers. I included the google dns servers as defaults. Then run `Configure.ps1`. This will take this JSON and build out a .db and Corefile for coredns, and a .env file. 

Right now the .env file really only has 1 env variable that is useful, and that is the Grafana admin password. The `Configure.ps1` script will generate a random password for this. 

## Squid
I used this to get a good conifg: https://github.com/gmellini/squidproxy-conf

## Operation
This is designed to run with `docker-compose up -d --build` There are 2 env variables that must be set on the machine running this:
```
[Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", "basicAuth", "Process")
[Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", "basicAuth", "Process")
```

See the registry in a web browser: <https://localhost:5000/v2/_catalog>

The registry ui at: http://localhost:8000/

Grafana at: https://localhost:3000

and prometheus at: http://localhost:9090/graph

## Volume backups
There are 2 powershell scripts to help with the backup and restore of the registry volume. These will stop the registry container, tar the volume with the registry data, then write the tar.gz to a bind point local to this docker-compose and copy it to a network location. The restore will pull the most recent from the network location and un tar into the volume.  


## to push and image to our registry
First tag a local image:
`docker image ls`

```
REPOSITORY                                      TAG                 IMAGE ID            CREATED             SIZE
mcr.microsoft.com/mssql/server                  latest              
```

then tag it to the registry:

`docker image tag mcr.microsoft.com/mssql/server  localhost:5000/mcr.microsoft.com/mssql/server`

You can see the new image if you `docker image ls` 

```
REPOSITORY                                      TAG                 IMAGE ID            CREATED             SIZE
localhost:5000/mcr.microsoft.com/mssql/server   latest              d2520a2df464        2 months ago        1.51GB
```
then push it to our registry with: 

`docker push localhost:5000/mcr.microsoft.com/mssql/server`