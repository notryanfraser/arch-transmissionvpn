#!/bin/bash

# if transmission-daemon config file doesnt exist then copy stock config file
if [[ ! -f /config/settings.json ]]; then
	echo "[info] Transmission config file doesn't exist, copying default..."
	cp /home/nobody/transmission-daemon/settings.json /config/
fi

# force unix line endings conversion in case user edited core.conf with notepad
dos2unix /config/core.conf

# set default values for port and ip
tranmission_port="6890"
tranmission_ip="0.0.0.0"

# while loop to check ip and port
while true; do

	# reset triggers to negative values
	transmission_running="false"
	ip_change="false"
	port_change="false"

	if [[ "${VPN_ENABLED}" == "yes" ]]; then

		# run script to check ip is valid for tunnel device (will block until valid)
		source /home/nobody/getvpnip.sh

		# if vpn_ip is not blank then run, otherwise log warning
		if [[ ! -z "${vpn_ip}" ]]; then

			# if current bind interface ip is different to tunnel local ip then re-configure transmission
			if [[ "${transmission_ip}" != "${vpn_ip}" ]]; then

				echo "[info] Transmission listening interface IP ${transmission_ip} and VPN provider IP ${vpn_ip} different, marking for reconfigure"

				# mark as reload required due to mismatch
				ip_change="true"

			fi

			# check if transmission-daemon is running
			if ! pgrep -fa "transmission-daemon" > /dev/null; then

				echo "[info] Transmission not running"

			else

				transmission_running="true"

			fi

			# run scripts to identify external ip address
			source /home/nobody/getvpnextip.sh

			if [[ "${VPN_PROV}" == "pia" ]]; then

				# run scripts to identify vpn port
				source /home/nobody/getvpnport.sh

				# if vpn port is not an integer then dont change port
				if [[ ! "${VPN_INCOMING_PORT}" =~ ^-?[0-9]+$ ]]; then

					# set vpn port to current transmission port, as we currently cannot detect incoming port (line saturated, or issues with pia)
					VPN_INCOMING_PORT="${transmission_port}"

					# ignore port change as we cannot detect new port
					port_change="false"

				else

					if [[ "${transmission_running}" == "true" ]]; then

						# run netcat to identify if port still open, use exit code
						nc_exitcode=$(/usr/bin/nc -z -w 3 "${vpn_ip}" "${transmission_port}")

						if [[ "${nc_exitcode}" -ne 0 ]]; then

							echo "[info] Transmission incoming port closed, marking for reconfigure"

							# mark as reconfigure required due to mismatch
							port_change="true"

						fi

					fi

					if [[ "${transmission_port}" != "${VPN_INCOMING_PORT}" ]]; then

						echo "[info] Transmission incoming port $transmission_port and VPN incoming port ${VPN_INCOMING_PORT} different, marking for reconfigure"

						# mark as reconfigure required due to mismatch
						port_change="true"

					fi

				fi

			fi

			if [[ "${port_change}" == "true" || "${ip_change}" == "true" || "${transmission_running}" == "false" ]]; then

				# run script to start transmission
				source /home/nobody/transmission.sh

			fi

		else

			echo "[warn] VPN IP not detected, VPN tunnel maybe down"

		fi

	else

		# check if transmission-daemon is running
		if ! pgrep -fa "transmission-daemon" > /dev/null; then

			echo "[info] Transmission not running"

		else

			transmission_running="true"

		fi

		if [[ "${transmission_running}" == "false" ]]; then

			# run script to start transmission
			source /home/nobody/transmission.sh

		fi

	fi

	if [[ "${DEBUG}" == "true" && "${VPN_ENABLED}" == "yes" ]]; then

		if [[ "${VPN_PROV}" == "pia" && -n "${VPN_INCOMING_PORT}" ]]; then

			echo "[debug] VPN incoming port is ${VPN_INCOMING_PORT}"
			echo "[debug] Transmission incoming port is ${transmission_port}"

		fi

		echo "[debug] VPN IP is ${vpn_ip}"
		echo "[debug] Transmission IP is ${transmission_ip}"

	fi

	sleep 30s

done
