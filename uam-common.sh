#!/bin/sh

LIBDIR="$(dirname "$0")"

# Read configuration

conf_read() {
	local D F

	for D in "${LIBDIR}" '/etc/udev'; do
		F="${D}/uam.conf"
		if [ -f "${F}" ]; then
			. "${F}"
			return 0
		fi
	done

	return 1
}

conf_read

# Parse value of boolean variable.
# If second arg is specified, it is printed if the value evalutes to true.
# If third arg is specified, it is printed if the value evaluates to false.

bool() {
	case "$1" in
		1|[yY]|[tT]|[yY][eE][sS]|[tT][rR][uU][eE]|[oO][nN])
			[ -n "$2" ] && echo $2
			return 0;;
		0|[nN]|[fF]|[nN][oO]|[fF][aA][lL][sS][eE]|[oO][fF][fF])
			[ -n "$3" ] && echo $3
			return 1;;
		*)
			outmsg "Incorrect value in bool ($1), assuming false."
			[ -n "$3" ] && echo $3
			return 1;;
	esac
}

# Check whether value is a correct integer.

isint() {
	local VAL
	VAL="$1"
	
	: $(( VAL *= 1 ))

	[ "${VAL}" = "$1" ]
}

# Determine whether we were called by udev.

under_udev() {
	[ -n "${DEVNAME}" ]
}

# If running under udev, output specified message using syslog
# else just print it into STDERR.

outmsg() {
	if under_udev; then
		logger -p info -t "$(basename "$0")[${DEVNAME}]" "$@"
	else
		echo "$@" >&2
	fi
}

# Output msg using outmsg() when ${VERBOSE} is on.

debug() {
	bool "${VERBOSE}" && outmsg "$@"
}

# Output msg using outmsg() when ${VERBOSE} is off.

summary() {
	bool "${VERBOSE}" || outmsg "$@"
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

MP_NOTEFN=".created_by_uam"

# Get processed array.

getarray() {
	echo "$1" | awk -f "${LIBDIR}/array.awk"
}

# Execute provided function for each of array elements.
# Function should return false to break the loop, else true.

foreach() {
	local FUNC ARR
	ARR="$1"
	FUNC="$2"

	# pass max 4 args to the func
	local ADDARGA ADDARGB ADDARGC ADDARGD
	ADDARGA="$3"
	ADDARGB="$4"
	ADDARGC="$5"
	ADDARGD="$6"

	eval set -- "$(getarray "${ARR}")"
	while [ $# -gt 0 ]; do
		"${FUNC}" "$1" "${ADDARGA}" "${ADDARGB}" "${ADDARGC}" "${ADDARGD}" || break
		shift
	done
}

# Create parent directories whenever needed
mkdir_parents() {
	local PAR
	PAR="${1%/*}"

	if [ ! -d "${PAR}" ]; then
		debug "...... trying to create ${PAR}"
		mkdir -m "${PARENT_PERMS}" -p "${PAR}"
	fi
}

# Create mountpoint if it doesn't exist.

mp_create() {
	local MP NOTEFILE
	MP="$1"
	NOTEFILE="${MP}/${MP_NOTEFN}"

	# we need to call it instead of using 'mkdir -p' below
	# because we want parents to have another permissions
	mkdir_parents "${MP}"
	if [ ! -d "${MP}" ]; then
		debug "... trying to create ${MP}"
		mkdir -m "${MP_PERMS}" "${MP}"
		date -u "+%D %T $$" > "${NOTEFILE}"
	fi
}

# Remove mountpoint if it's ours.

mp_remove() {
	bool "${REMOVE_MOUNTPOINTS}" || return

	local MP NOTEFILE
	MP="$1"
	NOTEFILE="${MP}/${MP_NOTEFN}"

	if [ -f "${NOTEFILE}" ]; then
		# SUS doesn't allow us to use readlink
		# so we need to do the symlink search first to find NOTEFILEs
		mp_rmsymlinks "$(cat "${NOTEFILE}")"

		rm "${NOTEFILE}"
		rmdir "${MP}"
		if [ $? -eq 0 ]; then
			debug "...... successfully removed mp ${MP}."
		else
			# touch the file again, so if above rm succeeded and rmdir failed,
			# we still will know that's our mountpoint
			touch "${NOTEFILE}"
			debug "...... unable to remove mp ${MP}."
		fi
	fi
}

# Calculate -maxdepth for given templates.

mp_getmaxdepth() {
	local DEPTH ARR
	DEPTH="${CLEANUP_MAXDEPTH}"
	ARR="$1"

	if ! isint "${DEPTH}"; then
		DEPTH=0
		function mp_countslashes() {
			local MP
			MP="$(echo "$1" | tr -cd /)"
			[ ${#MP} -gt ${DEPTH} ] && DEPTH=${#MP}

			return 0
		}

		foreach "${ARR}" mp_countslashes
	fi

	echo $(( DEPTH + 1 ))
}

# Find and remove symlinks to mountpoint.

mp_rmsymlinks() {
	local UPID NOTEFILE
	UPID="$1"
	bool "${CLEANUP_SYMLINKS}" || return

	find "${MOUNTPOINT_BASE}" $(bool "${CLEANUP_XDEV}" -xdev) \
			-maxdepth $(mp_getmaxdepth "${SYMLINK_TEMPLATES}") \
			-type l \
			-exec "${LIBDIR}/find-helper.sh" --remove-symlink '{}' ';'
}

# Remove unused mountpoints (useful if user umounts our devices himself).
# Doesn't support more complex templates.

mp_cleanup() {
	bool "${CLEANUP_ALLOW}" || return
	local D MP MAXDEPTH
	MAXDEPTH=$(mp_getmaxdepth "${MOUNTPOINT_TEMPLATES}")

	find "${MOUNTPOINT_BASE}" $(bool "${CLEANUP_XDEV}" -xdev) -mindepth 2 \
			-maxdepth $(( MAXDEPTH + 1 )) \
			-name "${MP_NOTEFN}" -type f \
			-exec "${LIBDIR}/find-helper.sh" --remove-mountpoint '{}' ';'
}

# Determine whether a mountpoint is used and print the device it is used by.

mp_used() {
	awk "\$2 == \"$1\" { print \$1 }" /proc/mounts
}

# Determine whether a device is mounted and print the mountpoint it uses.

mp_find() {
	awk "\$1 == \"$1\" { print \$2 }" /proc/mounts
}

# Gets MOUNT_OPTS correct for specific filesystem. If there are no specific opts
# set, uses global ones.

get_mountopts() {
	local FS VAL
	FS="$(echo "$1" | tr a-z A-Z | tr -cd A-Z)"

	[ -n "${FS}" ]	&& VAL="$(eval "echo \${MOUNT_OPTS_${FS}"})"
	[ -z "${VAL}" ]	&& VAL="${MOUNT_OPTS}"

	echo "${VAL}"
}

