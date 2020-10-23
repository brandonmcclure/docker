ARG IMAGE=python:3.5.2-slim 
FROM $IMAGE

LABEL maintainer="brandonmcclure89@gmail.com" Description="This image can be used for packageing python modules"

ENV PAT=''
ENV AZURE_DEVOPS_ARTIFACT_REPO_URL=''
ENV AZURE_DEVOPS_ARTIFACT_REPO_NAME=''

RUN apt-get update \ 
&& apt-get install -y unixodbc-dev gcc g++ curl apt-transport-https \
&& python -m pip install --upgrade \
&& pip install --upgrade pip
RUN pip install -U setuptools wheel twine

# Install Powershell because that is how I roll
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
&& sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-jessie-prod jessie main" > /etc/apt/sources.list.d/microsoft.list' \ 
&& apt-get update \
&& apt-get install -y powershell
WORKDIR /work
COPY BuildPackage.ps1 BuildPackage.ps1
COPY Populatepypirc.ps1 Populatepypirc.ps1

WORKDIR /src
ENTRYPOINT ["pwsh", "/work/BuildPackage.ps1"]

VOLUME ["/src"]