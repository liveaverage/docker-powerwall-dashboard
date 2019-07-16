# Overview

This is based on the work of @rhodesman and his teslaPowerDash repo, but hopefully enables easier ramp up to start obtaining Powerwall 2 trend data.

# Usage

- Pull the container image:

```
podman pull liveaverage/powerwall-dashboard

## Optional if you're still using docker
## docker pull liveaverage/powerwall-dashboard
```


- Start the container, replacing `POWERWALL_IP` with the assigned IP address of your Powerwall and `LOCAL_INFLUXDB_PATH` with an appropriate destination to store trend data:

```
export POWERWALL_IP=192.168.1.92
export LOCAL_INFLUXDB_PATH=/tmp/influxdata

podman run --add-host teslapw:${POWERWALL_IP} -p 3000:3000 -v ${LOCAL_INFLUXDB_PATH}:/var/lib/influxdb:z liveaverage/powerwall-dashboard

## Optional if you're still using docker:
## docker run --add-host teslapw:${POWERWALL_IP} -p 3000:3000 -v ${LOCAL_INFLUXDB_PATH}:/var/lib/influxdb:z liveaverage/powerwall-dashboard
 
```
- Access the Grafana dashboard from your container host IP, which may require firewall exceptions for TCP3000: http://localhost:3000
