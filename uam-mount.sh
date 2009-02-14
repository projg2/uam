#!/bin/bash

debug() {
	logger -p info -t "$(basename "$0")" "$@"
#	echo "$@" >&2
}

DEVPATH="${DEVNAME:-$1}"

if [ -z "${DEVPATH}" ]; then
	debug "No device supplied."
	exit 1
fi

debug "Starting uam mounter on ${DEVPATH}."

if [ -z "${DEVNAME}" ]; then # env not populated by udev
	__ENV="$(/lib/udev/vol_id --export "${DEVPATH}")"

	if [ $? -eq 0 ]; then
		eval "${__ENV}"
	else
		debug "... unable to get device information."
		exit 1
	fi
fi

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
			for _MP in "${ID_FS_LABEL}" "${DEVICE#/dev/}"; do
				MP="/media/${_MP}"
				[ -z "${_MP}" ] && continue
				MPDEV="$(awk "\$2 == \"${MP}\" { print \$1 }" /proc/mounts)"

				if [ -z "${MPDEV}" ]; then
					if [ ! -d "${MP}" ]; then
						debug "... trying to create ${MP}"
						mkdir -p "${MP}"
						touch "${MP}/.created_by_uam"
					fi

					if [ ! -d "${MP}" ]; then
						debug "...... unable to create mountpoint, trying another one."
					else
						debug "... mountpoint ${MP} free, using it."
						sg plugdev "mount -o umask=07 '${DEVPATH}' '${MP}'"
						MPDEV="$(awk "\$2 == \"${MP}\" { print \$1 }" /proc/mounts)"
						if [ "${MPDEV}" == "${DEVPATH}" ]; then
							debug "...... mount succeeded."
						elif [ -n "${MPDEV}" ]; then
							debug "...... ${MPDEV} mounted in our mointpoint (expected ${DEVPATH})."
						else
							debug "...... mount failed."
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
