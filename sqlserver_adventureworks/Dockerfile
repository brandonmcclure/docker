 # Default image is: mcr.microsoft.com/mssql/server:2017-CU8-ubuntu
# I am not explicitly adding this so that our CI never builds an image that we do not explicitly tell it.
ARG IMAGE 
FROM $IMAGE

LABEL maintainer="brandonmcclure89@gmail.com" Description="Runs MS adventure works in a container" 

USER root
ARG CD_SA_PASSWORD

 # Install Unzip
RUN apt-get update \
    && apt-get install unzip -y

# Install SQLPackage for Linux and make it executable
RUN wget -progress=bar:force -q -O sqlpackage.zip https://go.microsoft.com/fwlink/?linkid=873926 \
    && unzip -qq sqlpackage.zip -d /opt/sqlpackage \
    && chmod +x /opt/sqlpackage/sqlpackage

# create directory within SQL container for database files
RUN ["/bin/mkdir", "-p", "/var/opt/mssql/backup"]
RUN ["/bin/mkdir", "-p", "/var/opt/mssql/dbfiles"]
 
COPY *.sh /
COPY *.sql / 
#copy the database files from host to container
COPY AdventureWorksDW2019.bak /var/opt/mssql/backup/
COPY AdventureWorks2019.bak /var/opt/mssql/backup/

ENV ACCEPT_EULA="Y"
ENV SA_PASSWORD=$CD_SA_PASSWORD
HEALTHCHECK --interval=30s --timeout=3s --start-period=120s --retries=10 \
   CMD /opt/mssql-tools/bin/sqlcmd -S localhost -d master -V16 -U sa -P $SA_PASSWORD -Q "SELECT 1" || exit 1

CMD /bin/bash ./entrypoint.sh

