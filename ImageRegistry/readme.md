# Synopsis
We need a repository of images that we will build/deploy to as well as pull from.

[Docker docs](<https://docs.docker.com/registry/>)

This is designed to run with `docker-compose up -d --build` It will run a container for cfssl to run as a intermediate CA, and then the registry app will get a certificate from this container. It also has a UI, grafana and prometheus attached to it as well. 

This expects a CA certificate (`docker.crt`) and key (`docker.key`) for signing, and a `ca-bundle.crt` bundle/chain of the signing cert/up to the root CA located at `/mountpoints/ca`
# Volume backups
There are 2 powershell scripts to help with the backup and restore of the registry volume. 

# Operations
See the registry in a web browser: <https://localhost:5000/v2/_catalog>

The registry ui at: http://localhost:8000/

Grafana at: http://localhost:3000

and prometheus at: http://localhost:9090/graph

Checkout the [Docker Registry api docs](<https://docs.docker.com/registry/spec/api/>)

Can make it surfaced to others by setting the insecure-registries in the client machine's docker dameon [config file](<https://docs.docker.com/engine/reference/commandline/dockerd/>)
```
"insecure-registries": [
"hostIPAddress:5000"   
]
```


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