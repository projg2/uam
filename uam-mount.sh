#!/bin/bash

. "$(dirname "$0")/uam-common.sh"

DEVPATH="${DEVNAME:-$1}"

if [ -z "${DEVPATH}" ]; then
	debug "No device supplied."
	exit 1
fi

debug "Starting uam mounter on ${DEVPATH}."

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
			for _MP in "${ID_FS_LABEL}" "${DEVPATH#/dev/}"; do
				MP="/media/${_MP}"
				[ -z "${_MP}" ] && continue
				MPDEV="$(mp_used "${MP}")"

				if [ -z "${MPDEV}" ]; then
					mp_create "${MP}"

					if [ ! -d "${MP}" ]; then
						debug "...... unable to create mountpoint, trying another one."
					else
						debug "... mountpoint ${MP} free, using it."
						mount -o umask=07,gid=plugdev "${DEVPATH}" "${MP}"
						MPDEV="$(mp_used "${MP}")"
						if [ "${MPDEV}" == "${DEVPATH}" ]; then
							debug "...... mount succeeded."
						elif [ -n "${MPDEV}" ]; then
							debug "...... ${MPDEV} mounted in our mointpoint (expected ${DEVPATH})."
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
