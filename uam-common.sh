#!/bin/bash

# Determine whether we were called by udev.

under_udev() {
	[ -n "${DEVNAME}" ]
}

# If running under udev, output specified message using syslog
# else just print it into STDERR.

debug() {
	if under_udev; then
		logger -p info -t "$(basename "$0")" "$@"
	else
		echo "$@" >&2
	fi
}

mp_create() {
	local MP="$1"
	local NOTEFILE="${MP}/.created_by_uam"

	if [ ! -d "${MP}" ]; then
		debug "... trying to create ${MP}"
		mkdir -p "${MP}"
		touch "${NOTEFILE}"
	fi
}

mp_remove() {
	local MP="$1"
	local NOTEFILE="${MP}/.created_by_uam"

	if [ -f "${NOTEFILE}" ]; then
		rm "${NOTEFILE}"
		rmdir "${MP}"
		if [ $? -eq 0 ]; then
			debug "...... successfully removed our mountpoint."
		else
			# touch the file again, so if above rm succeeded and rmdir failed,
			# we still will know that's our mountpoint
			touch "${NOTEFILE}"
			debug "...... unable to remove our mountpoint."
		fi
	fi
}

mp_used() {
	awk "\$2 == \"$1\" { print \$1 }" /proc/mounts
}

mp_find() {
	awk "\$1 == \"$1\" { print \$2 }" /proc/mounts
}
