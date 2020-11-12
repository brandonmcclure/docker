This document is me keeping track of misc cool things I can do with docker. 

# Make
Building stuff with make:
## go
```
docker run --rm -i -t -v $PWD:/v -w /v golang:1.14 make
```

# Linting/formatting
## yml files
The best solution I have found is to use https://github.com/adrienverge/yamllint

apecifically the docker image: https://github.com/cytopia/docker-yamllint

I like to create a config file: `docker-compose.yamllint.config.yaml` next to your Docker-compose file and put the following in: 
```
# this YamlLint configuration is desgined to run for Docker-Compose.yaml files

extends: default

rules:
  line-length: disable
```
Then run the container in the directory with you docker-compose file and pass in yout config file. 

```
docker run --rm -it -v ${pwd}:/data cytopia/yamllint Docker-compose.yml -c docker-compose.yamllint.config.yaml
```

## squid config files
```
docker run --rm -it -v ${pwd}:/etc/squid --entrypoint squid localhost:5000/sameersbn/squid -k check
```

Output from failure:
```
2020/11/10 07:50:01| WARNING: BCP 177 violation. Detected non-functional IPv6 loopback.
2020/11/10 07:50:01| ACL not found: okay2
2020/11/10 07:50:01| FATAL: Bungled /etc/squid/squid.conf line 29: http_access allow okay2
2020/11/10 07:50:01| Squid Cache (Version 4.13): Terminated abnormally.
CPU Usage: 0.033 seconds = 0.019 user + 0.014 sys
Maximum Resident Size: 54752 KB
Page faults with physical i/o: 0
```

# Get files out of volume
With a running container
```
docker cp <containerId>:/file/path/within/container /host/path/target
``````

# Certificates and stuff
Stand up CFSSL to do a SSL scan
```
docker run -p 8888:8888 cfssl/cfssl serve -address 127.0.0.1
```
