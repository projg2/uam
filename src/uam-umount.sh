#!/bin/sh
# uam -- unmounter script
# (c) 2008-2010 Michał Górny
# Released under the terms of the 3-clause BSD license

LIBDIR=$(dirname "${0}")

. "${LIBDIR}"/uam-common.sh

DEVPATH=${DEVNAME:-${1}}

if [ -z "${DEVPATH}" ]; then
	conf_read
	debug "No device supplied."
	exit 1
fi

# We (try to) umount all mounts (not only ours), because the device will
# be unavailable anyway.

mp=$(mp_find "${DEVPATH}")
conf_read

# for hooks
MOUNTPOINT=${mp%%/}

debug "Starting uam umounter on ${DEVPATH}."
hook_exec pre-umount

RET=0
if [ -n "${mp}" ]; then
	debug "... found ${DEVPATH} mounted in ${mp}, trying to umount."
	umount "${DEVPATH}"
	if [ ${?} -eq 0 ]; then
		debug "...... standard umount successful."
		summary "umounted sucessfully."

		# If we created the mountpoint, try to remove it.
		mp_remove "${mp}"
	else
		unset ro_done
		if bool "${UMOUNT_TRY_RO}" && mount -o remount,ro "${DEVPATH}"; then
			debug "...... filesystem remounted read-only."
			ro_done=1
		fi

		if bool "${UMOUNT_TRY_LAZY}" && umount -l "${DEVPATH}"; then
			debug "...... lazy umount successful."
			summary "${ro_done+remounted R/O and }scheduled lazy umount."
		else
			RET=${?}
			debug "...... unable to umount device."
			summary "umount failed."
		fi
	fi

	hook_exec post-umount
else
	debug "... not mounted."
	# It is possible that user umounted the fs him/herself, so cleanup
	# the mountpoints.
	mp_cleanup
fi

exit ${RET}
