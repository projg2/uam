#!/bin/false
# uam -- common functions
# (c) 2008-2010 Michał Górny
# Released under the terms of the 3-clause BSD license

# LIBDIR should be declared by caller
[ -z "${LIBDIR}" ] && exit 1

CONFDIR="${LIBDIR}"/..

# Real system libdir
SYSLIBDIR=/lib

# The directory with hooks
HOOKDIR="${CONFDIR}"/uam-hooks

# Currently not used, only for informational purposes
# Empty means we're using SVN trunk
VERSION=

# <source> conf_read()
# Read the configuration file and enable tracing if requested.

conf_read() {
	. "${CONFDIR}"/uam.conf

	if [ -n "${TRACE}" ]; then
		exec >> "${TRACE}" 2>&1
		printf 'uam %s @ ' "${VERSION}"
		date
		env
		set -x
	fi
}

# Declare local() function if shell doesn't support 'local' builtin.

local_supported() {
	local test 2>/dev/null
}

local_supported || eval 'local() {
	:
}'

# <bool[+stdout]> bool( <value> [<if-true>] [<if-false>] )
# Parse the value of a boolean variable, returning the appropriate
# return code. If <if-true> is specified, that string will be echoed
# if the variable evaluates to true. If <if-false> is specified, it will
# be echoed otherwise.

bool() {
	case "${1}" in
		1|[yY]|[tT]|[yY][eE][sS]|[tT][rR][uU][eE]|[oO][nN])
			[ -n "${2}" ] && echo ${2}
			return 0;;
		0|[nN]|[fF]|[nN][oO]|[fF][aA][lL][sS][eE]|[oO][fF][fF])
			[ -n "${3}" ] && echo ${3}
			return 1;;
		*)
			outmsg "Incorrect value in bool (${1}), assuming false."
			[ -n "${3}" ] && echo ${3}
			return 1;;
	esac
}

# <bool> isint( <value> )
# Check whether the value is a correct integer.

isint() {
	local val
	val=${1}
	
	: $(( val *= 1 ))

	[ "${val}" = "${1}" ]
}

# <bool> under_udev()
# Determine whether we were called by udev.

under_udev() {
	[ -n "${DEVNAME}" ]
}

# [<stderr>] outmsg( <message> [...] )
# If running under udev, output specified message using syslog;
# otherwise simply print it to STDERR.

outmsg() {
	if under_udev; then
		local ident prio

		ident="$(basename "${0}")[${DEVNAME}]"
		prio=info

		logger -p ${prio} -t "${ident}" ${*}
		case ${?} in
			0)
				;;
			126|127)
				# No 'logger' util, try falling back to perl.
				echo ${*} | perl -MSys::Syslog -e "undef \$/; openlog('${ident}'); syslog('${prio}', <>);"
				;;
			default)
				# A syntax error? Try the POSIX-compliant one.
				logger ${*}
		esac
	else
		echo ${*} >&2
	fi
}

# [<stderr>] debug( <message> [...] )
# Output msg using outmsg() if ${VERBOSE} is on.

debug() {
	bool "${VERBOSE}" && outmsg "${@}"
}

# <env[+stderr]> summary( <message> [...] )
# Output msg using outmsg() if ${VERBOSE} is off.

summary() {
	SUMMARY=${@}
	bool "${VERBOSE}" || outmsg "${@}"
}

# <env+bool> env_populate()
# Populate the environment with the device information.

env_populate() {
	# udev already does this for us.
	if ! under_udev; then
		local __env ret
		if [ -x /sbin/blkid ]; then
			__env=$(/sbin/blkid -o udev "${DEVPATH}")
		elif [ -x "${SYSLIBDIR}"/udev/vol_id ]; then
			__env=$("${SYSLIBDIR}"/udev/vol_id --export "${DEVPATH}")
		else
			false
		fi

		if [ ${?} -eq 0 ]; then
			eval "${__env}"
		else
			return 1
		fi
	fi

	# uam-specific variables
	DEVBASENAME=$(basename "${DEVPATH}")
	SERIAL=${ID_SERIAL%-${ID_INSTANCE}}
	PARTN=${DEVBASENAME##*[^0-9]}

	return 0
}

MP_NOTEFN=".created_by_uam"

# <stdout> getarray( <array> )
# Output the processed array.

getarray() {
	echo "${1}" | awk -f "${LIBDIR}"/array.awk
}

# <callback> foreach( <array-name> <callback-func> [<arg1> .. <arg4>] )
# where <callback-func> should be:
# <bool> <callback-func>( <array-elem> [<arg1> .. <arg4>] )
# 
# Call the provided function for each of the array elements, passing
# that element and <arg1> to <arg4>. If the function wishes to break
# out of the loop, it shall return false. Otherwise, it shall return
# true.

foreach() {
	local func arrname
	arrname=${1}
	func=${2}

	# Pass max 4 arguments to the func.
	local addarga addargb addargc addargd
	addarga=${3}
	addargb=${4}
	addargc=${5}
	addargd=${6}

	local isarray arrtest

	# Maybe it's an bash-alike array?
	arrtest=$(declare -p ${arrname})

	case "${arrtest}" in
		'declare -a'*)
			isarray=1
			;;
		*)
			isarray=0
	esac

	if [ ${isarray} -eq 1 ]; then
		eval set -- '"${'${arrname}'[@]}"'
	else
		eval set -- "$(eval getarray '"${'${arrname}'}"')"
	fi

	while [ ${#} -gt 0 ]; do
		"${func}" "${1}" "${addarga}" "${addargb}" "${addargc}" "${addargd}" || break
		shift
	done
}

# mkdir_parents( <path> )
# Create parent directories whenever needed.

mkdir_parents() {
	local par
	par=${1%/*}

	if [ ! -d "${par}" ]; then
		debug "...... trying to create ${par}"
		mkdir -m "${PARENT_PERMS}" -p "${par}"
	fi
}

# <source> hook_exec( <hook-type> )
# Evaluate the particular type of hooks. Please notice that in order to be able
# to modify certain environment variables, hooks are being executed through
# '.' (AKA 'source'). This means they should avoid 'exit', 'exec' and similar
# calls.

hook_exec() {
	local hooktype fn
	hooktype=${1}

	if [ -d "${HOOKDIR}"/"${hooktype}" ]; then
		for fn in "${HOOKDIR}"/"${hooktype}"/*; do
			if [ -f "${fn}" ]; then
				debug "... ${hooktype}: evaluating $(basename "${fn}")"
				. "${fn}"
			fi
		done
	fi
}

# mp_create( <mountpoint-path> )
# Create the mountpoint if it doesn't exist yet.

mp_create() {
	local mp notefile
	mp=${1}
	notefile=${mp}/${MP_NOTEFN}

	# we need to call it instead of using 'mkdir -p' below
	# because we want parents to have another permissions
	mkdir_parents "${mp}"
	if [ ! -d "${MP}" ]; then
		debug "... trying to create ${mp}"
		mkdir -m "${MP_PERMS}" "${mp}"
		date -u "+%D %T ${$}" > "${notefile}"
	fi
}

# mp_remove( <mountpoint-path> )
# Remove mountpoint if it's ours.

mp_remove() {
	bool "${REMOVE_MOUNTPOINTS}" || return

	local mp notefile
	mp=${1}
	notefile=${mp}/${MP_NOTEFN}

	if [ -f "${notefile}" ]; then
		# POSIX doesn't allow us to use readlink, so we need to
		# do a symlink search to find the notefiles.
		mp_rmsymlinks "$(cat "${notefile}")"

		rm "${notefile}"
		if rmdir "${mp}"; then
			debug "...... successfully removed mp ${mp}."
		else
			# Touch the file again, so if the above rm succeeded
			# and rmdir failed, we will still own the mountpoint.
			touch "${notefile}"
			debug "...... unable to remove mp ${mp}."
		fi
	fi
}

# <env> _mp_countslashes( <path> )
# Count slashes in the <path> and increase ${DEPTH} as necessary.

_mp_countslashes() {
	local mp
	mp=$(echo "${1}" | tr -c -d /)
	[ ${#mp} -gt ${DEPTH} ] && DEPTH=${#mp}
	:
}

# <stdout> mp_getmaxdepth( <array-name> )
# Calculate -maxdepth for given templates.

mp_getmaxdepth() {
	local DEPTH arrname
	DEPTH=${CLEANUP_MAXDEPTH}
	arrname=${1}

	if ! isint "${DEPTH}"; then
		DEPTH=0
		foreach ${arrname} _mp_countslashes
	fi

	echo $(( DEPTH + 1 ))
}

# mp_rmsymlinks( <pid> )
# Find and remove symlinks to the mountpoint matching PID <pid>.

mp_rmsymlinks() {
	local UPID
	bool "${CLEANUP_SYMLINKS}" || return

	UPID=${1}
	export UPID

	find "${MOUNTPOINT_BASE}" $(bool "${CLEANUP_XDEV}" -xdev) \
			-maxdepth $(mp_getmaxdepth SYMLINK_TEMPLATES) \
			-type l \
			-exec "${LIBDIR}/find-helper.sh" --remove-symlink {} +
}

# mp_cleanup()
# Remove the unused mountpoints (useful if user umounts our device
# him-/herself). Won't work with more complex templates.

mp_cleanup() {
	local maxdepth
	bool "${CLEANUP_ALLOW}" || return
	maxdepth=$(mp_getmaxdepth MOUNTPOINT_TEMPLATES)

	find "${MOUNTPOINT_BASE}" $(bool "${CLEANUP_XDEV}" -xdev) \
			-mindepth 2 -maxdepth $(( maxdepth + 1 )) \
			-name "${MP_NOTEFN}" -type f \
			-exec "${LIBDIR}/find-helper.sh" --remove-mountpoint {} +
}

# <stdout> mp_used( <mountpoint-path> )
# Determine whether a particular mountpoint is used and print the device
# which is mounted in it.

mp_used() {
	awk -f "${LIBDIR}/mounts.awk" -v mp="${1}" /proc/mounts
}

# <stdout> mp_find( <device-path> )
# Determine whether a device is mounted and print the mountpoint it is
# mounted in.

mp_find() {
	awk -f "${LIBDIR}/mounts.awk" -v dev="${1}" /proc/mounts
}

# <stdout> get_mountopts( <filesystem> )
# Get the MOUNT_OPTS_* correct for a specific filesystem.
# If no filesystem-specific are set, global MOUNT_OPTS are used.

get_mountopts() {
	local fs val
	fs=$(echo "${1}" | tr a-z- A-Z_ | tr -cd A-Z0-9_)

	[ -n "${fs}" ]	&& val=$(eval "echo \${MOUNT_OPTS_${fs}"})
	[ -z "${val}" ]	&& val=${MOUNT_OPTS}

	echo "${val}"
}
