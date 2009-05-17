# /proc/mounts parsing with escapes support
# (c) 2009 Michał Górny

function unescape(str) {
	gsub(/\\012/, "\n", str)
	gsub(/\\040/, " ", str)
	gsub(/\\011/, "\t", str)
	gsub(/\\015/, "\r", str) # not currently escaped but there were requests for escaping it
	gsub(/\\\\/, "\\", str)

	return str
}

mp && unescape($2) == mp {
	print unescape($1)
	exit 0
}

dev && unescape($1) == dev {
	print unescape($2)
	exit 0
}
