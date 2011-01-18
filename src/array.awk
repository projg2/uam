# uam -- bash-alike array processing
# (c) 2009 Michał Górny
# Released under the terms of the 3-clause BSD license

BEGIN {
	ORS = ""

	inbslash = 0
	indquote = 0
	insquote = 0
	wasspace = 0
	hadfirst = 0
}

{
	len = length($0)

	for (i = 1; i <= len; i++) {
		ch = substr($0, i, 1)
		isspace = match(ch, /[ \t\r\n]/)

		# wasspace can't be set when in*
		# so we need only simple check
		if (!isspace) {
			if (!hadfirst) {
				hadfirst = 1
			} else if (wasspace) {
				# strip comments
				if (ch == "#") {
					break
				}
				print " "
			}
			
			wasspace = 0
		}

		# entering or leaving quotes?
		if (ch == "\"" && !inbslash && !insquote) {
			indquote = !indquote
		} else if (ch == "'" && !inbslash && !indquote) {
			insquote = !insquote
		} else if (!indquote && !insquote && isspace) {
			wasspace = 1
		}

		# handle escaping
		if (ch == "\\") {
			inbslash = !inbslash
		} else {
			inbslash = 0
		}

		# print unless repeated space
		if (!wasspace) {
			print ch
		}
	}

	# if in quotes, we need to copy newlines
	# else replace them with space if necessary
	if (indquote || insquote || inbslash) {
		print "\n"
		inbslash = 0
	} else if (!wasspace) {
		wasspace = 1
	}
}

END {
	# fix to avoid syntax error
	# but return nonzero status

	if (insquote) {
		print "'"
		exit 1
	} else if (indquote) {
		print "\""
		exit 2
	} else if (inbslash) {
		print "\\"
		exit 3
	}
	
	exit 0
}
