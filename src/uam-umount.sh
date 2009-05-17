#!/bin/sh
# uam - umount
# (c) 2008/09 Michał Górny

LIBDIR="$(dirname "$0")"

. "${LIBDIR}"/uam-common.sh

DEVPATH="${DEVNAME:-$1}"

if [ -z "${DEVPATH}" ]; then
	debug "No device supplied."
	exit 1
fi

debug "Starting uam umounter on ${DEVPATH}."

# We (try to) umount all mounts (not only ours), because the device will be unavailable anyway

MP="$(mp_find "${DEVPATH}")"

if [ -n "${MP}" ]; then
	debug "... found ${DEVPATH} mounted in ${MP}, trying to umount."
	umount "${DEVPATH}"
	if [ $? -eq 0 ]; then
		debug "...... standard umount successful."
		summary "umounted sucessfully."

		# if we created the mountpoint, try to remove it
		mp_remove "${MP}"
	else
		unset RO_DONE
		if $(bool "${UMOUNT_TRY_RO}"); then
			mount -o remount,ro "${DEVPATH}"
			if [ $? -eq 0 ]; then
				debug "...... filesystem remounted read-only."
				RO_DONE=1
			fi
		fi

		bool "${UMOUNT_TRY_LAZY}" && umount -l "${DEVPATH}"
		if [ $? -eq 0 ]; then
			debug "...... lazy umount successful."
			summary "${RO_DONE+remounted R/O and }scheduled lazy umount."
		else
			debug "...... unable to umount device."
			summary "umount failed."
		fi
	fi
else
	debug "... not mounted."
	# it is possible that user umounted the fs him/herself, so cleanup the mountpoints
	mp_cleanup
fi

