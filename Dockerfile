FROM centos:8
MAINTAINER JR Morgan <jr@shifti.us>

LABEL Vendor="CentOS8" \
      License=GPLv2 \
      Version=1.0

## Supports x86_64 or aarch64
ARG TARGETARCH
ENV A_ARCH=$TARGETARCH \
    ARCH=$A_ARCH

ENV VERSION_INFLUXDB=1.8.6 \
    VERSION_TELEGRAF=1.19.0 \
    VERSION_GRAFANA=7.5.2-1

ENV POWERWALL_HOST="powerwall" \
    POWERWALL_PASS="002D" \
    POWERWALL_LOCATION="lat=36.2452052&lon=-113.7292593" \
    DATABASE="PowerwallData"

## Install prerequisites
RUN yum -y install epel-release \
    && yum -y --setopt=tsflags=nodocs install \
            initscripts \
            urw-fonts \
            cronie \
            jq \
            gettext

## Install Grafana
RUN export IARCH=$(([[ $A_ARCH == *"arm"* ]] && echo "armhfp") || ([[ $A_ARCH == *"amd64"* ]] && echo "amd64" )) && \
    echo "A_ARCH=${A_ARCH} IARCH=${IARCH} ARCH=${ARCH} OS arch=$(arch)" && \
    yum -y --setopt=tsflags=nodocs install https://dl.grafana.com/oss/release/grafana-${VERSION_GRAFANA}.$(arch).rpm && \
    yum -y clean all && \
    rm -rf /var/cache/yum

## Install Telegraf + InfluxDB via binary (missing repo arm pkgs)
RUN export IARCH=$(([[ $A_ARCH == *"arm"* ]] && echo "armhf") || ([[ $A_ARCH == *"amd64"* ]] && echo "amd64" )) \
    && echo "A_ARCH=${A_ARCH} IARCH=${IARCH} ARCH=${ARCH} OS arch=$(arch)" \
    && curl https://dl.influxdata.com/influxdb/releases/influxdb-${VERSION_INFLUXDB}_linux_${IARCH}.tar.gz -o influx.tar.gz \
    && curl https://dl.influxdata.com/telegraf/releases/telegraf-${VERSION_TELEGRAF}_linux_${IARCH}.tar.gz -o telegraf.tar.gz \
    && tar xvfz influx.tar.gz --strip=2 \
    && tar xvzf telegraf.tar.gz --strip=2

## Cleanup tar files
RUN rm -rf influx* telegraf*

## Defaults for InfluxDB
ENV INFLUXDB_HTTP_ENABLED=true \
    INFLUXDB_HTTP_BIND_ADDRESS="127.0.0.1:8086" \
    INFLUXDB_HTTP_AUTH_ENABLED=false \
    INFLUXDB_HTTP_LOG_ENABLED=true

## InfluxDB stores data by default at /var/lib/influxdb/[data|wal]
## which should be mapped to a docker/podman volume for persistence

RUN mkdir -p /etc/telegraf && \
    mkdir -p /etc/grafana/provisioning/dashboards \
        /etc/grafana/provisioning/datasources \
        /var/lib/grafana \
        /var/log/grafana \
        /var/lib/grafana/dashboards && \
    chown grafana:grafana /var/lib/grafana/dashboards

ADD powerwall.conf graf_DS.yaml graf_DA.yaml powerwallcookie.sh.template run.sh /tmp/

RUN mv /tmp/powerwall.conf /etc/telegraf/telegraf.d/powerwall.conf \
    && mv /tmp/graf_DS.yaml /etc/grafana/provisioning/datasources/graf_DS.yaml \
    && mv /tmp/graf_DA.yaml /etc/grafana/provisioning/dashboards/graf_DA.yaml \
    && mv /tmp/powerwallcookie.sh.template /etc/powerwallcookie.sh \
    && mv /tmp/run.sh /opt/run.sh \
    && rm -f /tmp/* \
    && chmod -v +x /opt/run.sh /etc/powerwallcookie.sh \
        && export $(grep -v "#" /etc/sysconfig/grafana-server | cut -d= -f1)

EXPOSE 3000

CMD ["/opt/run.sh"]
