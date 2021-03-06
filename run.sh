#!/bin/sh

/usr/local/bin/init_snap

# Start Snap daemon
snapteld -t ${SNAP_TRUST_LEVEL} -l ${SNAP_LOG_LEVEL} -o '' &
SNAP_PID=$(pidof snapteld)

echo
echo "[Process $SNAP_PID] Load plugins: docker, meminfo, pyustil, and influxdb."
echo

curl -sfL "http://snap.ci.snap-telemetry.io/plugins/snap-plugin-collector-meminfo/latest/linux/x86_64/snap-plugin-collector-meminfo" -o snap-plugin-collector-meminfo
curl -sfL "https://github.com/intelsdi-x/snap-plugin-publisher-influxdb/releases/download/16/snap-plugin-publisher-influxdb_linux_x86_64" -o snap-plugin-publisher-influxdb
curl -sfL "https://github.com/adrianliaw/snap-plugin-collector-docker/releases/download/5-name/snap-plugin-collector-docker_linux_x86_64" -o snap-plugin-collector-docker
curl -sfL "https://github.com/intelsdi-x/snap-plugin-collector-disk/releases/download/4/snap-plugin-collector-disk_linux_x86_64" -o snap-plugin-collector-disk
curl -sfL "https://github.com/intelsdi-x/snap-plugin-collector-psutil/releases/download/8/snap-plugin-collector-psutil_linux_x86_64" -o snap-plugin-collector-psutil

chmod 755 snap-plugin-*

snaptel plugin load snap-plugin-collector-meminfo > /dev/null
snaptel plugin load snap-plugin-publisher-influxdb > /dev/null
snaptel plugin load snap-plugin-collector-docker > /dev/null
snaptel plugin load snap-plugin-collector-disk > /dev/null
snaptel plugin load snap-plugin-collector-psutil > /dev/null

echo "Start Snap task."
echo
snaptel task create -t /etc/snap/snap-daemon.json
echo

wait $SNAP_PID
