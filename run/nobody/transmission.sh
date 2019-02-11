#!/bin/bash

if [[ "${transmission_running}" == "false" ]]; then

	echo "[info] Attempting to start Transmission..."

	echo "[info] Removing transmission pid file (if it exists)..."
	rm -f /config/transmission-daemon.pid

	# set listen interface ip address for transmission using python script
	#/home/nobody/config_transmission.py "${transmission_ip}"

	# run transmission daemon (daemonized, non-blocking)
	/usr/bin/transmission-daemon -i "${vpn_ip}" -T -g /config -e /config/transmission-daemon.log

	# make sure process transmission-daemon DOES exist
	retry_count=30
	while true; do

		if ! pgrep -fa "transmission-daemon" > /dev/null; then

			retry_count=$((retry_count-1))
			if [ "${retry_count}" -eq "0" ]; then

				echo "[warn] Wait for Transmission daemon process to start aborted"
				break

			else

				if [[ "${DEBUG}" == "true" ]]; then
					echo "[debug] Waiting for Transmission daemon process to start..."
				fi

				sleep 1s

			fi

		else

			echo "[info] Transmission process started"
			break

		fi

	done

	echo "[info] Waiting for Transmission process to start listening on port 51413..."

	while [[ $(netstat -lnt | awk "\$6 == \"LISTEN\" && \$4 ~ \".51413\"") == "" ]]; do
		sleep 0.1
	done

else

	# set listen interface ip address for transmission
	/usr/bin/transmission-daemon -g /config -i "${vpn_ip}"

fi

# change incoming port using the transmission console
if [[ "${VPN_PROV}" == "pia" && -n "${VPN_INCOMING_PORT}" ]]; then

	# set incoming port
	/usr/bin/transmission-remote -p "${VPN_INCOMING_PORT}"

	# set transmission port to current vpn port (used when checking for changes on next run)
	transmission_port="${VPN_INCOMING_PORT}"

fi

# run script to check we don't have any torrents in an error state
#/home/nobody/torrentcheck.sh

# set transmission ip to current vpn ip (used when checking for changes on next run)
transmission_ip="${vpn_ip}"
