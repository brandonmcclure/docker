# Default image is: mcr.microsoft.com/mssql/server:2017-CU8-ubuntu
# I am not explicitly adding this so that our CI never builds an image that we do not explicitly tell it.
ARG IMAGE 
FROM $IMAGE
USER root
ARG CD_SA_PASSWORD

 # Install Unzip
RUN apt-get update \
    && apt-get install unzip -y

# Install SQLPackage for Linux and make it executable
RUN wget -progress=bar:force -q -O sqlpackage.zip https://go.microsoft.com/fwlink/?linkid=873926 \
    && unzip -qq sqlpackage.zip -d /opt/sqlpackage \
    && chmod +x /opt/sqlpackage/sqlpackage

# pwsh
RUN apt-get install -y wget apt-transport-https \
&& wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& apt-get update \
&& apt-get install -y powershell

# create directory within SQL container for database files
RUN /bin/mkdir -p /var/opt/mssql/backup
RUN /bin/mkdir -p /var/opt/mssql/dbfiles

COPY entrypoint.sh /
COPY init.sh /
COPY installTSQLT.sql /
COPY installTSQLT.ps1 /

ENV ACCEPT_EULA="Y"
ENV SA_PASSWORD=$CD_SA_PASSWORD
 
 EXPOSE 1433
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=10 \
   CMD /opt/mssql-tools/bin/sqlcmd -S localhost -d master -V16 -U sa -P $SA_PASSWORD -Q "SELECT 1" || exit 1


CMD /bin/bash ./entrypoint.sh