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

debug "Starting uam umounter on ${DEVPATH}."

# We (try to) umount all mounts (not only ours), because the device will be unavailable anyway

MP="$(awk "\$1 == \"${DEVPATH}\" { print \$2 }" /proc/mounts)"

if [ -n "${MP}" ]; then
	debug "... found ${DEVPATH} mounted in ${MP}, trying to umount."
	umount "${DEVPATH}"
	if [ $? -eq 0 ]; then
		debug "...... standard umount succeeded."

		# if we created the mountpoint, try to remove it
		if [ -f "${MP}/.created_by_uam" ]; then
			rm "${MP}/.created_by_uam"
			rmdir "${MP}"
			if [ $? -eq 0 ]; then
				debug "...... successfully removed our mountpoint."
			else
				# touch the file again, so if above rm succeeded and rmdir failed,
				# we still will know that's our mountpoint
				touch "${MP}/.created_by_uam"
				debug "...... unable to remove our mountpoint."
			fi
		fi
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
fi

