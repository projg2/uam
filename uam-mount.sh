#!/bin/bash

. "$(dirname "$0")/uam-common.sh"

DEVPATH="${DEVNAME:-$1}"

if [ -z "${DEVPATH}" ]; then
	debug "No device supplied."
	exit 1
fi

debug "Starting uam mounter on ${DEVPATH}."

conf_read
env_populate

if [ "${ID_FS_TYPE}" != "swap" ]; then
	# 1) try to mount using fstab, this way we also determine if it's already mounted
	mount "${DEVPATH}"
	case $? in
		0)
			debug "... mounted due to fstab.";;
		32)
			debug "... already mounted!";;
		*)

			# 2) find a free mountpoint for it
			DEVBASENAME="$(basename "${DEVPATH}")"
			SERIAL="${ID_SERIAL%-${ID_INSTANCE}}"
			PARTN="${DEVBASENAME//[^0-9]/}"
			for _MP in ${MOUNTPOINT_TEMPLATES[@]}; do
				_MP_EVAL="$(eval echo ${_MP})"
				[ -z "${_MP_EVAL}" ] && continue
				MP="${MOUNTPOINT_BASE}/${_MP_EVAL%/}"
				MPDEV="$(mp_used "${MP}")"

				if [ -z "${MPDEV}" ]; then
					mp_create "${MP}"

					if [ ! -d "${MP}" ]; then
						debug "...... unable to create mountpoint, trying another one."
					else
						debug "... mountpoint ${MP} free, using it."
						mount -o "$(get_mountopts "${ID_FS_TYPE}")" "${DEVPATH}" "${MP}"

						if [ $? -eq 0 ]; then
							debug "...... mount successful."
						else
							debug "...... mount failed."
							# maybe we've created a mountpoint already
							mp_remove "${MP}"
							exit 1
						fi
					fi
					exit 0
				else
					debug "... mountpoint ${MP} already used for ${MPDEV}."
				fi
			done
		;;
	esac
fi

