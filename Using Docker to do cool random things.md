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