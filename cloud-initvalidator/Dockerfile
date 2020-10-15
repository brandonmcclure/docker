FROM ubuntu:18.04

RUN apt update && apt install cloud-init -y
ENTRYPOINT ["cloud-init", "devel", "schema", "--config-file", "/home/cloud-init"]