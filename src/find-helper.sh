#!/bin/sh
# uam - helper for 'find -exec'
# (c) 2009 Michał Górny

[ ${#} -ge 2 ] || exit 1

LIBDIR=$(dirname "${0}")

. "${LIBDIR}"/uam-common.sh
conf_read

case "${1}" in
	--remove-mountpoint)
		while [ ${#} -gt 1 ]; do
			d=$(dirname "${2}")
			mp=$(mp_used "${d}")

			[ -z "${mp}" ] && mp_remove "${d}"
			shift
		done
		;;
	--remove-symlink)
		while [ ${#} -gt 1 ]; do
			# POSIX doesn't give us readlink...
			d=${2}
			notefile=${d}/${MP_NOTEFN}
			shift

			[ ! -f "${notefile}" ] && continue # not our symlink
			[ "$(cat "${notefile}")" != "${UPID}" ] && continue # not this symlink

			if rm "${d}"; then
				debug "...... successfully removed symlink ${d}."
			else
				debug "...... unable to remove symlink ${d}."
			fi
		done
		;;
	*)
		exit 1
		;;
esac

exit 0
