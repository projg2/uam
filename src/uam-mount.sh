#!/bin/sh
# uam -- mounter script
# (c) 2008-2010 Michał Górny
# Released under the terms of the 3-clause BSD license

LIBDIR=$(dirname "${0}")

. "${LIBDIR}"/uam-common.sh

try_symlink() {
	local _sp sp mp # sp stands for 'symlink point'
	_sp=${1}
	mp=${2}

	[ -z "${_sp}" ] && return 0
	sp=${MOUNTPOINT_BASE}/${_sp%%/}

	debug "... trying symlink ${sp}"
	if [ "${sp}" = "${mp}" ]; then
		debug "...... skipping since we used it as a mountpoint."
		return 0
	elif [ -L "${sp}" ]; then
		if [ -e "${sp}" ]; then
			# XXX: check whether target is mounted and whether it's uam mountpoint
			debug "...... skipping as it's working symlink."
			return 0
		else
			debug "...... is a broken symlink, removing and reusing it."
			rm -f "${sp}"
		fi
	elif [ -e "${sp}" ]; then
		debug "...... skipping as it exists and is not a symlink."
		return 0
	fi

	mkdir_parents "${sp}"
	if ln -s "${mp}" "${sp}"; then
		debug "...... symlink created."
	else
		debug "...... symlink failed."
	fi

	return 0
}

try_mountpoint() {
	local _mp mp mpdev MOUNTPOINT
	_mp=${1}

	[ -z "${_mp}" ] && return 0
	mp=${MOUNTPOINT_BASE}/${_mp%%/}
	mpdev=$(mp_used "${mp}")

	if [ -z "${mpdev}" ]; then
		mp_create "${mp}"

		# for hooks
		MOUNTPOINT=${mp}

		if [ ! -d "${mp}" ]; then
			debug "...... unable to create mountpoint, trying another one."
			return 0
		else
			local mountoutput
			debug "... mountpoint ${mp} free, using it."
			mountoutput=$(mount -o $(get_mountopts "${ID_FS_TYPE}") "${DEVPATH}" "${mp}" 2>&1)

			if [ ${?} -eq 0 ]; then
				debug "...... mount successful."
				summary "mounted successfully in ${mp}."
			else
				debug "...... mount failed: ${mountoutput}."
				summary "mount failed: ${mountoutput}."
				# Maybe we've created a mountpoint already.
				mp_remove "${mp}"
				hook_exec mount-failed
				exit 1
			fi
		fi

		foreach SYMLINK_TEMPLATES try_symlink "${mp}"
		# If getting a change request, look for orphans.
		[ ${ACTION} = change ] && mp_cleanup

		hook_exec post-mount
		exit 0
	else
		debug "... mountpoint ${mp} already used for ${mpdev}."
	fi

	return 0
}

DEVPATH=${DEVNAME:-${1}}

if [ -z "${DEVPATH}" ]; then
	conf_read
	debug "No device supplied."
	exit 1
fi

if ! env_populate; then
	conf_read
	debug "... unable to get device information."
	exit 1
fi

conf_read

debug "Starting uam mounter on ${DEVPATH}."
hook_exec pre-mount

if [ "${ID_FS_TYPE}" != "swap" ]; then
	# 1) try to mount using fstab, this way we also determine if it's already mounted
	mount "${DEVPATH}"
	case ${?} in
		0)
			debug "... mounted due to fstab."
			summary "mounted due to fstab.";;
		32)
			debug "... already mounted!"
			summary "ignoring, already mounted!";;
		*)
			# 2) find a free mountpoint for it
			foreach MOUNTPOINT_TEMPLATES try_mountpoint

			debug "... no more mountpoints, failing."
			summary "unable to find a free mountpoint."
			hook_exec mount-failed
			exit 1
		;;
	esac
fi
