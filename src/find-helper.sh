#!/bin/sh
# uam - helper for 'find -exec'
# (c) 2009 Michał Górny

[ $# -ge 1 ] || exit 1

LIBDIR="$(dirname "$0")"

. "${LIBDIR}"/uam-common.sh

case "$1" in
	--remove-mountpoint)
		[ $# -ge 2 ] || exit 1

		D="$(dirname "$2")"
		MP="$(mp_used "${D}")"

		[ -z "${MP}" ] && mp_remove "${D}"
		;;
	--remove-symlink)
		[ $# -ge 2 ] || exit 1
		# SUS - readlink's not there

		D="$2"
		NOTEFILE="${D}/${MP_NOTEFN}"
		[ ! -f "${NOTEFILE}" ]					&& exit 1 # not our symlink
		[ "$(cat "${NOTEFILE}")" != "${UPID}" ]	&& exit 1 # not this symlink

		conf_read
		if rm "${D}"; then
			debug "...... successfully removed symlink ${D}."
		else
			debug "...... unable to remove symlink ${D}."
		fi
		;;
	*)
		exit 1
		;;
esac

exit 0
