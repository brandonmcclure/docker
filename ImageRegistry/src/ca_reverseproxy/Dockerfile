FROM nginx:1.19.3-alpine

RUN apk add --no-cache \
    openssl \
    gettext

ARG basicAuthUsername=""
ARG basicAuthPassword=""
ENV AuthUsername=$basicAuthUsername
ENV AuthPassword=$basicAuthPassword

ARG ForwardPort=8888
ARG ForwardHost
ENV FORWARD_PORT=$ForwardPort \
    FORWARD_HOST=$ForwardHost

ARG httpPort=80
ARG httpsPort=443
ENV HTTP_PORT=$httpPort \
HTTPS_PORT=$httpsPort

WORKDIR /opt

COPY auth.conf launch.sh ./

# If we build the iamge with a AuthUsername argument/env variable then create the htpasswd file and update the auth.conf file to let nginx know to use basic auth
RUN mkdir /auth \
&& if [ ! -z "${AuthUsername}" ]; then printf "$AuthUsername:$(openssl passwd -crypt $AuthPassword)\n" >> /opt/auth.htpasswd; sed -i $'s/location \/ {/location \/ {\\\n auth_basic\\n"Restricted"; \\\nauth_basic_user_file    auth.htpasswd;/' /opt/auth.conf; fi

CMD ["./launch.sh"]