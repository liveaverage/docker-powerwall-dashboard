FROM centos:7
MAINTAINER JR Morgan <jr@shifti.us>

LABEL Vendor="CentOS7" \
      License=GPLv2 \
      Version=1.0

## Supports x86_64 or aarch64
ARG TARGETARCH
ENV A_ARCH=$TARGETARCH

ENV ARCH=$A_ARCH 
ENV VERSION_INFLUXDB=1.8.4 \ 
    VERSION_TELEGRAF=1.18.0 \
    VERSION_GRAFANA=7.5.2-1

ENV POWERWALL_HOST="teslapw"
ENV POWERWALL_PASS="002D"
ENV DATABASE="PowerwallData"

#ADD powerwall.repo /etc/yum.repos.d/powerwall.repo

RUN yum -y install epel-release
RUN yum -y --setopt=tsflags=nodocs install \
	https://dl.grafana.com/oss/release/grafana-${VERSION_GRAFANA}.$(arch).rpm \
	initscripts \
	urw-fonts \
	cronie \
        gettext

## Install Telegraf + InfluxDB via binary (missing repo arm pkgs)
RUN export IARCH=$(([[ $A_ARCH == *"arm"* ]] && echo "armhf") || ([[ $A_ARCH == "x86_64" ]] && echo "amd64" )) && \
    echo "IARCH=${IARCH} ARCH=${ARCH} OS arch=$(arch)" && \
    curl https://dl.influxdata.com/influxdb/releases/influxdb-${VERSION_INFLUXDB}_linux_${IARCH}.tar.gz -o influx.tar.gz && \
    curl https://dl.influxdata.com/telegraf/releases/telegraf-${VERSION_TELEGRAF}_linux_${IARCH}.tar.gz -o telegraf.tar.gz && \
    tar xvfz influx.tar.gz --strip=2 && \
    tar xvzf telegraf.tar.gz --strip=2

## Defaults for InfluxDB
ENV INFLUXDB_HTTP_ENABLED=true \
    INFLUXDB_HTTP_BIND_ADDRESS="127.0.0.1:8086" \
    INFLUXDB_HTTP_AUTH_ENABLED=false \
    INFLUXDB_HTTP_LOG_ENABLED=true

## InfluxDB stores data by default at /var/lib/influxdb/[data|wal]
## which should be mapped to a docker/podman volume for persistence

RUN mkdir -p /etc/telegraf && \ 
    mkdir -p /var/lib/grafana/dashboards && \
    chown grafana:grafana /var/lib/grafana/dashboards

ADD powerwall.conf /etc/telegraf/telegraf.d/powerwall.conf
ADD graf_DS.yaml /etc/grafana/provisioning/datasources/graf_DS.yaml
ADD graf_DA.yaml /etc/grafana/provisioning/dashboards/graf_DA.yaml
ADD powerwallcookie.sh.template /etc/powerwallcookie.sh


EXPOSE 3000

ADD run.sh /opt/run.sh
RUN chmod -v +x /opt/run.sh /etc/powerwallcookie.sh
RUN export $(grep -v "#" /etc/sysconfig/grafana-server | cut -d= -f1)

ENV POWERWALL_LOCATION="lat=36.2452052&lon=-113.7292593"

CMD ["/opt/run.sh"]
