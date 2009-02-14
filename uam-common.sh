#!/bin/bash

# Read configuration

conf_read() {
	local D F

	for D in "$(dirname "$0")" '/etc/udev'; do
		F="${D}/uam.conf"
		if [ -f "${F}" ]; then
			. "${F}"
			return 0
		fi
	done

	return 1
}

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

# Populate environment with device information.

env_populate() {
	# udev already does this for us
	if ! under_udev; then
		__ENV="$(/lib/udev/vol_id --export "${DEVPATH}")"

		if [ $? -eq 0 ]; then
			eval "${__ENV}"
		else
			debug "... unable to get device information."
			exit 1
		fi
	fi
}

# Create mountpoint if it doesn't exist.

mp_create() {
	local MP="$1"
	local NOTEFILE="${MP}/.created_by_uam"

	if [ ! -d "${MP}" ]; then
		debug "... trying to create ${MP}"
		mkdir -p "${MP}"
		touch "${NOTEFILE}"
	fi
}

# Remove mounpoint if it's ours.

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

# Determine whether a mountpoint is used and print the device it is used by.

mp_used() {
	awk "\$2 == \"$1\" { print \$1 }" /proc/mounts
}

# Determine whether a device is mounted and print the mountpoint it uses.

mp_find() {
	awk "\$1 == \"$1\" { print \$2 }" /proc/mounts
}
