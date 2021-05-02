# Synopsis
This started as me setting up a docker registry. It has morphed to include a CA, DNS, prometheus to collect metrics, . 

This is used for my learning and should not be used by anyone for anything "production" related. Feel free to PR or raise issues if you have any problems though, as I am interested in learning what works and what does not.


# Quick start
You wil need GNU make; pwsh core; docker/docker-compose. 

Copy the `config/config.example` file to `config/config.json` and update your DNS forwarder at a minimum. This file drives the setup of the nginx ingress, and service specific .env files. 

Run `Configure.ps1` It will prompt you for the IP address and domain to use. The IP address is what will be used in the CoreDNS configuration for any records in `config.json` that have a `localhost` type. You can also manually set IP addresses in the `config.json` to get DNS entries for other services running on your network that are not managed in these files. 

I use a intermediate CA/key signed by my network's CA to act as the signer for the PKI. This allow me to revoke the intermediate CA if this docker network is compromised. You can generate your own with OpenSSL. The `Configure.ps1` script will not run until there are 3 files related to the PKI: `ca-bundle.crt`, `docker.crt` and `docker.key`. ca-bundle.crt is a composite certificate with my root CA and Int CA. `docker.crt` is the int ca, and `docker.key` is the private key for the int CA. These files will be surfaced as a bind mount into the CA container, and should be considered unsecure. **Do not use this in production, or with truly secret CAs!**

Run `make core` from this directory. That will start the CFSSL/PKI, DNS, Certgetter and ingress services.

Run `make registry` to start the registry/registry UI services. 

Run `make monitoring` to start prometheus, grafana and nagios services. 

Run `make elastic` starts up a 3 node elastic cluster and kibana. 

There are a few other make targets you can use, checkout the `Makefile` for more info. 


# Long start
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
This is designed to run with `docker-compose up -d --build` 

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

# To Generate basicAuth credentials
cd .\mountPoints\ingress\basicAuth\; docker run --rm -ti xmartlabs/htpasswd brandon basicAuth 
> htpasswd