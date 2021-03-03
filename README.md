# Overview

This is based on the work of [@rhodesman](https://github.com/rhodesman) and his [teslaPowerDash](https://github.com/rhodesman/teslaPowerDash) repo, but hopefully enables easier ramp up to start obtaining and trending Powerwall 2 API data.

# Preview

<a href="https://i.imgur.com/GtP725k.png" ><img src="https://i.imgur.com/GtP725k.png" alt="Grafana Dashboard Preview" width="50%"/></a>

# Usage

If you're still using docker rather than podman, simply replace all `podman` calls with `docker`.

- Pull the container image:

```
podman pull liveaverage/powerwall-dashboard
```


- Start the container, replacing `POWERWALL_IP` with the assigned IP address of your Powerwall and `LOCAL_INFLUXDB_PATH` with an appropriate destination to store trend data:

```
export POWERWALL_IP=192.168.1.92
export POWERWALL_PASS=002C
export LOCAL_INFLUXDB_PATH=/tmp/influxdata
export LOCAL_GRAFANA_PATH=/tmp/grafana
export GRAFANA_WEATHER_LOCATION="lat=36.2452052&lon=-80.7292593"
export GRAFANA_DASHBOARD_URL="https://raw.githubusercontent.com/liveaverage/docker-powerwall-dashboard/master/graf_dash.json"

podman run --add-host teslapw:${POWERWALL_IP} -p 3000:3000 \
	-e "POWERWALL_PASS=${POWERWALL_PASS}" \
        -e "GRAFANA_DASHBOARD_URL=${GRAFANA_DASHBOARD_URL}" \
        -e "POWERWALL_LOCATION=${GRAFANA_WEATHER_LOCATION}" \
	-v ${LOCAL_INFLUXDB_PATH}:/var/lib/influxdb:z \
	-v ${LOCAL_GRAFANA_PATH}:/var/lib/grafana:z \
	liveaverage/powerwall-dashboard
 
```
- Access the Grafana dashboard from your container host IP, which may require firewall exceptions for TCP3000: http://localhost:3000
  - Default credentials are "admin" for username/password

