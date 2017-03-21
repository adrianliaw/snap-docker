#!/bin/sh

/usr/local/bin/init_snap

# Start Snap daemon
snapteld -t ${SNAP_TRUST_LEVEL} -l ${SNAP_LOG_LEVEL} --plugin-load-timeout 30 -o '' &
SNAP_PID=$(pidof snapteld)

echo
echo "[Process $SNAP_PID] Load plugins: docker, meminfo, pyustil, and influxdb."
echo

curl -sfL "http://snap.ci.snap-telemetry.io/plugins/snap-plugin-collector-meminfo/latest/linux/x86_64/snap-plugin-collector-meminfo" -o snap-plugin-collector-meminfo
curl -sfL "https://github.com/intelsdi-x/snap-plugin-publisher-influxdb/releases/download/21/snap-plugin-publisher-influxdb_linux_x86_64" -o snap-plugin-publisher-influxdb
curl -sfL "https://github.com/intelsdi-x/snap-plugin-collector-docker/releases/download/7/snap-plugin-collector-docker_linux_x86_64" -o snap-plugin-collector-docker
curl -sfL "https://github.com/intelsdi-x/snap-plugin-collector-disk/releases/download/4/snap-plugin-collector-disk_linux_x86_64" -o snap-plugin-collector-disk
curl -sfL "https://github.com/intelsdi-x/snap-plugin-collector-psutil/releases/download/8/snap-plugin-collector-psutil_linux_x86_64" -o snap-plugin-collector-psutil

chmod 755 snap-plugin-*

echo "Load snap-plugin-collector-meminfo"
snaptel plugin load snap-plugin-collector-meminfo > /dev/null
echo "Load snap-plugin-publisher-influxdb"
snaptel plugin load snap-plugin-publisher-influxdb > /dev/null
echo "Load snap-plugin-collector-docker"
snaptel plugin load snap-plugin-collector-docker > /dev/null
echo "Load snap-plugin-collector-disk"
snaptel plugin load snap-plugin-collector-disk > /dev/null
echo "Load snap-plugin-collector-psutil"
snaptel plugin load snap-plugin-collector-psutil > /dev/null

chmod 755 /etc/snap/snap-intel.json
snaptel task create -t /etc/snap/snap-intel.json

if [ "IS$GODDD_URL" != "IS"  ]; then
        echo "Load snap-plugin-collector-goddd"
        chmod 755 snap-plugin-*
        snaptel plugin load snap-plugin-collector-goddd
        touch /etc/snap/snap-goddd.json

        jq '.workflow.collect.config."/hyperpilot/goddd".endpoint = "'"$GODDD_URL"'"' /etc/snap/snap-goddd-template.json >> /etc/snap/snap-goddd.json
        chmod 755 /etc/snap/snap-goddd.json
    else
        echo
        echo
        echo "GODDD_URL is undefined. $GODDD_URL"
        exit 1
fi

echo "Start Snap task."
echo
snaptel task create -t /etc/snap/snap-goddd.json
echo

wait $SNAP_PID
