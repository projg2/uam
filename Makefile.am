rules_DATA = 80-uam.rules
script_DATA = uam-common.sh
script_SCRIPTS = uam-mount.sh uam-umount.sh find-helper.sh

dist_script_DATA = src/array.awk src/mounts.awk
dist_conf_DATA = uam.conf

mfhookdir = ${hookdir}/mount-failed
mbhookdir = ${hookdir}/pre-mount
mahookdir = ${hookdir}/post-mount
ubhookdir = ${hookdir}/pre-umount
uahookdir = ${hookdir}/post-umount

dist_mfhook_DATA = uam-hooks/mount-failed/90_sw_notify
dist_mahook_DATA = uam-hooks/post-mount/90_sw_notify
dist_uahook_DATA = uam-hooks/post-umount/90_sw_notify
ubhook_DATA = .keep
mbhook_DATA = .keep

EXTRA_DIST = 80-uam.rules.in \
		src/uam-common.sh src/uam-mount.sh src/uam-umount.sh src/find-helper.sh
MOSTLYCLEANFILES = $(rules_DATA) $(script_DATA) $(script_SCRIPTS) .keep

$(rules_DATA): Makefile
	rm -f $@ $@.tmp
	@SED@ -e "s|/lib/udev/uam|${scriptdir}|" ${srcdir}/$@.in > $@.tmp
	chmod a-w $@.tmp
	mv $@.tmp $@

$(script_SCRIPTS): Makefile
	rm -f $@ $@.tmp
	@SED@ -e "s|^\(LIBDIR=\).*$$|\1${scriptdir}|" ${srcdir}/src/$@ > $@.tmp
	chmod +x $@.tmp
	chmod a-w $@.tmp
	mv $@.tmp $@

$(script_DATA): Makefile
	rm -f $@ $@.tmp
	@SED@ \
		-e 's|^\(CONFDIR=\).*$$|\1${confdir}|' \
		-e 's|^\(SYSLIBDIR=\).*$$|\1${libdir}|' \
		-e 's|^\(HOOKDIR=\).*$$|\1${hookdir}|' \
		-e "s|^\(VERSION=\).*$$|\1@VERSION@|" \
		${srcdir}/src/$@ > $@.tmp
	chmod +x $@.tmp
	chmod a-w $@.tmp
	mv $@.tmp $@

.keep:
	touch $@

80-uam.rules: 80-uam.rules.in
uam-common.sh: src/uam-common.sh
uam-mount.sh: src/uam-mount.sh
uam-umount.sh: src/uam-umount.sh
find-helper.sh: src/find-helper.sh