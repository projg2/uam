#!/bin/sh
# uam - mount
# (c) 2008/09 Michał Górny

LIBDIR="$(dirname "$0")"

. "${LIBDIR}"/uam-common.sh

try_symlink() {
	local _SP SP MP # SP = symlink point
	_SP="$1"
	MP="$2"

	[ -z "${_SP}" ] && return 0
	SP="${MOUNTPOINT_BASE}/${_SP%%/}"

	debug "... trying symlink ${SP}"
	if [ "${SP}" = "${MP}" ]; then
		debug "...... skipping since we used it as a mountpoint."
		return 0
	elif [ -L "${SP}" ]; then
		if [ -e "${SP}" ]; then
			# XXX: check whether target is mounted and whether it's uam mountpoint
			debug "...... skipping as it's working symlink."
			return 0
		else
			debug "...... is a broken symlink, removing and reusing it."
			rm -f "${SP}"
		fi
	elif [ -e "${SP}" ]; then
		debug "...... skipping as it exists and is not a symlink."
		return 0
	fi

	mkdir_parents "${SP}"
	ln -s "${MP}" "${SP}"
	if [ $? -eq 0 ]; then
		debug "...... symlink created."
	else
		debug "...... symlink failed."
	fi

	return 0
}

try_mountpoint() {
	local _MP MP MPDEV
	_MP="$1"

	[ -z "${_MP}" ] && return 0
	MP="${MOUNTPOINT_BASE}/${_MP%%/}"
	MPDEV="$(mp_used "${MP}")"

	if [ -z "${MPDEV}" ]; then
		mp_create "${MP}"

		if [ ! -d "${MP}" ]; then
			debug "...... unable to create mountpoint, trying another one."
			return 0
		else
			local mountoutput
			debug "... mountpoint ${MP} free, using it."
			mountoutput="$(mount -o "$(get_mountopts "${ID_FS_TYPE}")" "${DEVPATH}" "${MP}" 2>&1)"

			if [ $? -eq 0 ]; then
				debug "...... mount successful."
				summary "mounted successfully in ${MP}."
			else
				debug "...... mount failed: ${mountoutput}."
				summary "mount failed: ${mountoutput}."
				# maybe we've created a mountpoint already
				mp_remove "${MP}"
				hook_exec mount-failed
				exit 1
			fi
		fi

		foreach "${SYMLINK_TEMPLATES}" try_symlink "${MP}"

		hook_exec post-mount
		exit 0
	else
		debug "... mountpoint ${MP} already used for ${MPDEV}."
	fi

	return 0
}

DEVPATH="${DEVNAME:-$1}"

if [ -z "${DEVPATH}" ]; then
	debug "No device supplied."
	exit 1
fi

debug "Starting uam mounter on ${DEVPATH}."

env_populate
conf_read
hook_exec pre-mount

if [ "${ID_FS_TYPE}" != "swap" ]; then
	# 1) try to mount using fstab, this way we also determine if it's already mounted
	mount "${DEVPATH}"
	case $? in
		0)
			debug "... mounted due to fstab."
			summary "mounted due to fstab.";;
		32)
			debug "... already mounted!"
			summary "ignoring, already mounted!";;
		*)
			# 2) find a free mountpoint for it
			DEVBASENAME="$(basename "${DEVPATH}")"
			SERIAL="${ID_SERIAL%-${ID_INSTANCE}}"
			PARTN="${DEVBASENAME##*[^0-9]}"

			foreach "${MOUNTPOINT_TEMPLATES}" try_mountpoint

			debug "... no more mountpoints, failing."
			summary "unable to find free mountpoint."
			hook_exec mount-failed
			exit 1
		;;
	esac
fi

