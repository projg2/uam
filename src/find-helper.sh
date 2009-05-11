#!/bin/sh
# Helper used for find -exec.

[ $# -ge 1 ] || exit 1

. "$(dirname "$0")/uam-common.sh"

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
		[ ! -f "${NOTEFILE}" ]					&& continue # not our symlink
		[ "$(cat "${NOTEFILE}")" != "${UPID}" ]	&& continue # not this symlink

		rm "${D}"
		if [ $? -eq 0 ]; then
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
