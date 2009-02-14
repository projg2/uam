#!/bin/bash

debug() {
	logger -p info -t "$(basename "$0")" "$@"
#	echo "$@" >&2
}

mp_remove() {
	local MP="$1"

	if [ -f "${MP}/.created_by_uam" ]; then
		rm "${MP}/.created_by_uam"
		rmdir "${MP}"
		if [ $? -eq 0 ]; then
			debug "...... successfully removed our mountpoint."
		else
			# touch the file again, so if above rm succeeded and rmdir failed,
			# we still will know that's our mountpoint
			touch "${MP}/.created_by_uam"
			debug "...... unable to remove our mountpoint."
		fi
	fi
}
