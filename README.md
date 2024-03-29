![GitHub Workflow](https://github.com/liveaverage/docker-powerwall-dashboard/actions/workflows/build_images.yml/badge.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/liveaverage/powerwall-dashboard)

> ⚠️ **DEPRECATION NOTICE**
> This monolith image is being deprecated in favor of the [podman-compose or docker-compose variant](https://github.com/liveaverage/dc-powerwall-dashboard) which works the same, utilizes vendor-maintained images [for x86 and aarch64], and decouples the services for easier troubleshooting.

# Overview

This is based on the work of [@rhodesman](https://github.com/rhodesman) and his [teslaPowerDash](https://github.com/rhodesman/teslaPowerDash) repo, but hopefully enables easier ramp up to start obtaining and trending Powerwall 2 API data. 

# Preview

<a href="https://i.imgur.com/GtP725k.png" ><img src="https://i.imgur.com/GtP725k.png" alt="Grafana Dashboard Preview" width="50%"/></a>

# Usage

If you're still using docker rather than podman, simply replace all `podman` calls with `docker`.

- Pull the container image:

```
podman pull quay.io/liveaverage/powerwall-dashboard:latest
```


- Start the container, replacing `POWERWALL_IP` with the assigned IP address of your Powerwall, `POWERWALL_PASS` with your Powerwall password (required for Cookie-based auth as of **February 2021**), and `LOCAL_INFLUXDB_PATH` with an appropriate destination to store trend data:

> The default Powerwall password may be the last 5 digits of your Backup Gateway.

> Note you *must* use a hostname map for `powerwall` due to changes in the API introduced in **June 2021**

```
export POWERWALL_IP=192.168.1.92
export POWERWALL_PASS=0R2D2
export LOCAL_INFLUXDB_PATH=/tmp/influxdata
export LOCAL_GRAFANA_PATH=/tmp/grafana
export GRAFANA_WEATHER_LOCATION="lat=36.2452052&lon=-80.7292593"
export GRAFANA_DASHBOARD_URL="https://raw.githubusercontent.com/liveaverage/docker-powerwall-dashboard/master/graf_dash.json"

podman run --add-host powerwall:${POWERWALL_IP} -p 3000:3000 \
	-e "POWERWALL_PASS=${POWERWALL_PASS}" \
        -e "GRAFANA_DASHBOARD_URL=${GRAFANA_DASHBOARD_URL}" \
        -e "POWERWALL_LOCATION=${GRAFANA_WEATHER_LOCATION}" \
	-v ${LOCAL_INFLUXDB_PATH}:/var/lib/influxdb:z \
	-v ${LOCAL_GRAFANA_PATH}:/var/lib/grafana:z \
	liveaverage/powerwall-dashboard
 
```
- Access the Grafana dashboard from your container host IP, which may require firewall exceptions for TCP3000: http://localhost:3000
  - Default credentials are "admin" for username/password

