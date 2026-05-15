ARG DOCKER_PREFIX=
ARG DOCKERHUB_PREFIX=

# Pre-requistite builds
FROM ${DOCKERHUB_PREFIX}golang:1.26 AS utilbuild

RUN mkdir -p /go/src/local/utilsrc/
COPY utilsrc/ /go/src/local/utilsrc/

WORKDIR /go/src/local/utilsrc/localip
RUN go build -o /go/bin/localip ./cmd/localip

FROM ${DOCKER_PREFIX}ubuntu:26.04

ARG URL_P2CLI=https://github.com/wrouesnel/p2cli/releases/download/r19/p2cli_r19_linux-amd64.tar.gz
ARG URL_NGINX_EXPORTER=https://github.com/wrouesnel/nginx_exporter/releases/download/v0.0.1/nginx_exporter
ARG URL_PG_EXPORTER=https://github.com/prometheus-community/postgres_exporter/releases/download/v0.19.1/postgres_exporter-0.19.1.linux-amd64.tar.gz
ARG URL_REVERSE_EXPORTER=https://github.com/wrouesnel/reverse_exporter/releases/download/v0.0.1/reverse_exporter_v0.0.1_linux-amd64.tar.gz
ARG URL_PROMETHEUS=https://github.com/prometheus/prometheus/releases/download/v3.11.3/prometheus-3.11.3.linux-amd64.tar.gz
ARG URL_ALERTMANAGER=https://github.com/prometheus/alertmanager/releases/download/v0.32.0/alertmanager-0.32.0.linux-amd64.tar.gz
ARG URL_NODEEXPORTER=https://github.com/prometheus/node_exporter/releases/download/v1.11.1/node_exporter-1.11.1.linux-amd64.tar.gz
ARG URL_WEBHOOK=https://github.com/wrouesnel/webhook/releases/download/2.6.8.streaming_responses/webhook-linux-amd64.tar.gz
ARG URL_MAKECERTS=https://github.com/wrouesnel/makecerts/releases/download/v2.0.0-beta0/makecerts_v2.0.0-beta0_linux-amd64.tar.gz
ARG URL_REDIS_EXPORTER=https://github.com/oliver006/redis_exporter/releases/download/v1.82.0/redis_exporter-v1.82.0.linux-amd64.tar.gz

ARG http_proxy=
ARG https_proxy=

COPY tree-preinstall/ /

RUN apt update && apt install --no-install-recommends -y gnupg2 ca-certificates curl

RUN curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

ENV POSTGRES_VERSION=18

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y \
    postgresql-${POSTGRES_VERSION} postgresql-${POSTGRES_VERSION}-repmgr barman barman-cli \
    redis-server \
    nginx-extras \
    runit \
    syslog-ng-core syslog-ng-mod-json \
    netcat-openbsd \
    openssl \
    pwgen \
    wget curl dnsutils apache2-utils net-tools iproute2 rsync sudo jq ssl-cert less expect nano lsb-release \
    # netbox depends
    libsasl2-dev \
    libjpeg-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    libldap2-dev \
    libssl-dev \
    libpq-dev python3 python3-dev build-essential uwsgi uwsgi-plugin-python3 && \
    # Templating engine
    wget --progress=dot:giga -O - $URL_P2CLI | tar -xzvf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/p2 && \
    # SSL certificate helper
    wget --progress=dot:giga -O - $URL_MAKECERTS | tar -xzvf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/makecerts && \
    # Prometheus monitoring for nginx
    wget -O /usr/local/bin/nginx_exporter $URL_NGINX_EXPORTER && \
    chmod +x /usr/local/bin/nginx_exporter && \
    # Prometheus monitoring for Postgres
    wget --progress=dot:giga -O - $URL_PG_EXPORTER | tar -xzvf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/postgres_exporter && \
    # Prometheus reverse proxy
    wget --progress=dot:giga -O - $URL_REVERSE_EXPORTER | tar -xzvf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/reverse_exporter && \
    # Prometheus node_exporter
    wget --progress=dot:giga -O - $URL_NODEEXPORTER | tar -xzvf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/node_exporter && \
    # Prometheus redis_exporter
    wget --progress=dot:giga -O - $URL_REDIS_EXPORTER | tar -xzvf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/redis_exporter && \
    # Prometheus
    mkdir -p /opt/prometheus && \
    wget --progress=dot:giga -O - $URL_PROMETHEUS | tar -xzvf - --strip-components=1 -C /opt/prometheus/ && \
    ln -sf /opt/prometheus/prometheus /usr/local/sbin/prometheus && \
    ln -sf /opt/prometheus/promtool /usr/local/sbin/promtool && \
    # Alertmanager
    mkdir -p /opt/alertmanager && \
    wget --progress=dot:giga -O - $URL_ALERTMANAGER | tar -xzvf - --strip-components=1 -C /opt/alertmanager/ && \
    ln -sf /opt/alertmanager/alertmanager /usr/local/sbin/alertmanager && \
    ln -sf /opt/alertmanager/amtool /usr/local/sbin/amtool && \
    # Webhook engine
    wget --progress=dot:giga -O - $URL_WEBHOOK | tar -xzvf - --strip-components=1 -C /usr/local/bin && \
    chmod +x /usr/local/bin/webhook && \
    # Cleanup    
    apt-get autoremove -y && \
    # Delete nginx default configuration.
    rm -rf /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/snippets /etc/nginx/conf.d && \
    rm -rf /var/lib/postgresql/*

# Static env-vars  - should not be overridden
ENV DATA_DIR=/data \
    SVDIR=/run/services \
    PG_RUN_DIR=/run/postgresql

# Python environment
ARG URL_GETPIP=https://bootstrap.pypa.io/get-pip.py
ARG URL_PYPI=https://pypi.python.org/simple

ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN echo "[global]\nindex-url = $URL_PYPI\n" > /etc/pip.conf && \
    for pyver in $(dpkg -l | grep -oP 'python\d(\.\d)?' | sort | uniq) ; do \
    mkdir -p /usr/lib/$pyver/distutils && \
    echo "[easy_install]\nindex-url = $URL_PYPI\n" > /usr/lib/$pyver/distutils/distutils.cfg ; \
    done

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH=$PATH:/root/.local/bin

# Netbox specific build profiles
RUN \ 
    # Install pip packages
    # pip3 install napalm ruamel.yaml django_auth_ldap napalm && \
    # Make directories
    mkdir -p /opt/netbox

# Copy the application
COPY src/netbox/ /opt/netbox/

RUN cd /opt/netbox \
 && uv sync \
 && uv pip install -r base_requirements.txt -r requirements.txt \
 && uv pip install django-auth-ldap django-auth-oidc \
 && uv pip install pyuwsgi \
 && ln -sf $DATA_DIR/netbox/static /opt/netbox/netbox/static \
 && ln -sf /opt/netbox/netbox/project-statics/docs /opt/netbox/netbox/docs

# Copy utility commands
#COPY --from=utilbuild /go/bin/promtargets /usr/local/bin/promtargets
#COPY --from=utilbuild /go/bin/amquorum /usr/local/bin/amquorum
COPY --from=utilbuild /go/bin/localip /usr/local/bin/localip

# Setup users and groups for netbox
RUN mkdir /var/lib/netbox && \
    addgroup --system netbox && \
    adduser --system --ingroup netbox --home /var/lib/netbox netbox && \
    chown netbox: /var/lib/netbox

ENV NETBOX_RUN_DIR=/run/netbox

# Setup configuration symlink for netbox
RUN ln -sf ${NETBOX_RUN_DIR}/configuration.py /opt/netbox/netbox/netbox/configuration.py && \
    ln -sf ${NETBOX_RUN_DIR}/ldap_config.py /opt/netbox/netbox/netbox/ldap_config.py

RUN rm -rf /etc/services && \
    mkdir /etc/services

COPY tree-postinstall/ /

# Setup the symlinks in the image for postgres.
RUN chown -R root:postgres /etc/postgresql && \
    rm -rf /etc/postgresql/18/main && \
    ln -sf $PG_RUN_DIR/conf /etc/postgresql/18/main

# The entrypoint generates a random password if the DB_USER_PASSWORD is unspecified.
ENV \
    CORE_COUNT=1 \
    HOSTNAME= \
    ADMIN_AUTH=yes \
    ADMIN_USER=admin \
    ADMIN_PASSWORD= \
    WEBUI_SSL_SERVER_CERT= \
    WEBUI_SSL_SERVER_KEY= \
    WEBUI_SSL_SERVER_CERTCHAIN= \
    WEBUI_DNS_NAME= \
    PSQL_USER=psql \
    PSQL_PASSWORD= \
    PSQL_DB= \
    PSQL_SSL_SERVER_CERT= \
    PSQL_SSL_SERVER_KEY= \
    PSQL_SSL_SERVER_CERTCHAIN= \
    PSQL_SSL_CLIENT_CACERT= \
    PSQL_SSL_CLIENT_CERT= \
    PSQL_SSL_CLIENT_KEY= \
    SMTP_SMARTHOST= \
    SMTP_FROM= \
    SMTP_USERNAME= \
    SMTP_PASSWORD= \
    ALERT_EMAIL_ADDRESSES= \
    DEV_ALLOW_SELF_SIGNED=no \
    DEV_ALLOW_EPHEMERAL_DATA=no \
    DEV_STANDALONE=no \
    DEV_ALLOW_DEFAULT_TRUST=no \
    DEV_NO_ALERT_EMAILS=no \
    DEV_ENTRYPOINT_DEBUG=no \
    PLATFORM_TLS_TRUST_CERTIFICATES= \
    PLATFORM_RUN_DURATION=21600

# Netbox config path
ENV \
    DEV_NETBOX_DEBUG=no \
    DEV_NETBOX_REMOTE_DEBUG_HOST=0.0.0.0 \
    DEV_NETBOX_REMOTE_DEBUG_PORT=51234 \
    DEV_NETBOX_REMOTE_DEBUG_ENABLE=no \
    NETBOX_WEB_SECRET= \
    NETBOX_CHANGELOG_RETENTION_DAYS=0 \
    NETBOX_PREFIX_PATH= \
    NETBOX_ADMIN_EMAIL= \
    NETBOX_ADMIN_NAME="Netbox Admin" \
    NETBOX_TIMEZONE=UTC \
    NETBOX_LDAP_AUTH=yes \
    NETBOX_LDAP_SERVER_URI= \
    NETBOX_LDAP_SERVER_BIND_DN=  \
    NETBOX_LDAP_SERVER_BIND_PASSWORD= \
    NETBOX_LDAP_USER_BASE_DN= \
    NETBOX_LDAP_USER_SEARCH_FILTER= \
    NETBOX_LDAP_USER_DN_TEMPLATE= \
    NETBOX_LDAP_GROUP_BASE_DN= \
    NETBOX_LDAP_GROUP_SEARCH_FILTER=(objectCategory=Group) \
    NETBOX_LDAP_GROUP_REQUIRED_DN= \
    NETBOX_LDAP_GROUP_USER_ACTIVE_DN= \
    NETBOX_LDAP_GROUP_USER_STAFF_DN= \
    NETBOX_LDAP_GROUP_USER_SUPERUSER_DN= 

# Override default TLS behavior in the container.
RUN \
    # Point SSL directory to /run
    mv /etc/ssl /etc/ssl.default && \
    mv /usr/local/share/ca-certificates /usr/local/share/ca-certificates.default && \
    ln -sf /run/ssl /etc/ssl && \
    # Point update-ca-certificates to /run so we can change configuration.
    mv /etc/ca-certificates.conf /etc/ca-certificates.conf.default && \
    ln -sf /run/ca-certificates.conf /etc/ca-certificates.conf && \
    # Point /usr/local/share/ca-certificates to /run
    rm -rf /usr/local/share/ca-certificates && \
    ln -sf /run/ca-certificates /usr/local/share/ca-certificates

EXPOSE 443/tcp 5432/tcp 561/tcp

COPY healthcheck.sh /healthcheck.sh
HEALTHCHECK --interval=10s --timeout=10s --retries=3 CMD /healthcheck.sh

ARG PYTHON_REMOTE_DEBUGGING=no
COPY debug /debug/
RUN if [ "$PYTHON_REMOTE_DEBUGGING" = "yes" ] ; then \
    echo "Debugging support requested." 1>&2 && \
    cp -vf /debug/wsgi.py /opt/netbox/netbox/netbox/wsgi.py ; \
    else \
    rm -rf /debug ; \
    fi


RUN \
    # Ensure some nginx paths exist
    mkdir /var/lib/nginx/body \
 && chown www-data:www-data /var/lib/nginx/body

ENTRYPOINT [ "/entrypoint.bsh" ]
