#!/bin/bash

. "$(dirname "$0")/uam-common.sh"

DEVPATH="${DEVNAME:-$1}"

if [ -z "${DEVPATH}" ]; then
	debug "No device supplied."
	exit 1
fi

debug "Starting uam umounter on ${DEVPATH}."

# We (try to) umount all mounts (not only ours), because the device will be unavailable anyway

MP="$(awk "\$1 == \"${DEVPATH}\" { print \$2 }" /proc/mounts)"

if [ -n "${MP}" ]; then
	debug "... found ${DEVPATH} mounted in ${MP}, trying to umount."
	umount "${DEVPATH}"
	if [ $? -eq 0 ]; then
		debug "...... standard umount succeeded."

		# if we created the mountpoint, try to remove it
		mp_remove "${MP}"
	else
		mount -o remount,ro "${DEVPATH}"
		[ $? -eq 0 ] && debug "...... filesystem remounted read-only."

		umount -l "${DEVPATH}"
		if [ $? -eq 0 ]; then
			debug "...... lazy umount succeeded."
		else
			debug "...... unable to umount device."
		fi
	fi
else
	debug "... not mounted."
fi

