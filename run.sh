#!/bin/bash

# Create/validate cookie for Powerwall API Auth

export POWERWALLIP="${POWERWALL_HOST}"         # This is your Powerwall IP or DNS Name -- we force a host entry to 'teslapw' so static is fine
export PASSWORD="${POWERWALL_PASS}"            # Login to the Powerwall UI and Set this password - follow the on-screen instructions
export USERNAME="customer"
export EMAIL="Lt.Dan@bubbagump.com"            # Set this to whatever you want, it's not actually used in the login process; I suspect Tesla will collect this eventually
export COOKIE="/var/tmp/PWcookie.txt"          # Feel free to change this location as you see fit.

# Workaround to ensure a couple of vars are left untouched
export COOKIE_AUTH='${COOKIE_AUTH}'
export COOKIE_REC='${COOKIE_REC}'
export ONE_DAY_AGO='${ONE_DAY_AGO}'
export FILE_TIME='${FILE_TIME}'

# Substitute all vars and dump to cron.hourly
envsubst < /etc/powerwallcookie.sh > /etc/PWcookie.sh
chmod a+x /etc/PWcookie.sh

# Initial run for auth cookie
bash -xe /etc/PWcookie.sh

# Create crontab entry
echo "0 * * * * /etc/PWcookie.sh" > /var/spool/cron/root

# Start crond in the foreground
/usr/sbin/crond -m off -n -s -p &

# Start influx
/usr/bin/influxd &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start influxd: $status"
  exit $status
fi


# Start telegraf:
/usr/bin/telegraf --config /etc/telegraf/telegraf.conf --config-directory /etc/telegraf/telegraf.d &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start telegraf: $status"
  exit $status
fi

set -a; . /etc/sysconfig/grafana-server; set +a

cd /usr/share/grafana

# Preconfigure grafana with required plugins and dashboards
mkdir -p /var/lib/grafana/dashboards
grafana-cli plugins install grafana-piechart-panel
curl ${GRAFANA_DASHBOARD_URL} > /var/lib/grafana/dashboards/grafana_powerwall.json
chown -R grafana:grafana /var/lib/grafana

/usr/sbin/grafana-server \
	--config=${CONF_FILE}                                   \
	--pidfile=${PID_FILE_DIR}/grafana-server.pid            \
	--packaging=rpm                                         \
	cfg:default.paths.logs=${LOG_DIR}                       \
	cfg:default.paths.data=${DATA_DIR}                      \
	cfg:default.paths.plugins=${PLUGINS_DIR}                \
	cfg:default.paths.provisioning=${PROVISIONING_CFG_DIR}

while sleep 60; do
  ps aux |grep influxd |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep telegraf |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done
