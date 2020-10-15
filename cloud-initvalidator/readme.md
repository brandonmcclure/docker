Basic image I made to validate my cloud-init/cloud-config scripts. 

build: `docker build -t cloud-init-validator .`

then run (from the directory with your `cloud-init` file in it) `docker run --rm -v ${PWD}:/home cloud-init-validator`