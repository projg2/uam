UPDIR		= ..
SRCDIR		= ../src

SCRIPTS		= uam-mount.sh uam-umount.sh find-helper.sh
SCRIPTS_NX	= uam-common.sh

UDEV_RULES	= 10-uam.rules
DEFLIBDIR	= /lib/udev/uam

all: $(SCRIPTS) $(SCRIPTS_NX) $(UDEV_RULES)
	@true

%.sh:
	sed -e 's:^\(LIBDIR=\).*$$:\1'"'"'$(SCRIPTDIR)'"':" \
		-e 's:^\(CONFDIR=\).*$$:\1'"'"'$(CONFIGDIR)'"':" \
		-e 's:^\(VERSION=\).*$$:\1$(VERSION):' \
		"$(SRCDIR)/$@" > "$@"

$(UDEV_RULES):
	sed -e 's:$(DEFLIBDIR):$(SCRIPTDIR):' \
		"$(UPDIR)/$@" > "$@"

clean:
	rm -f $(SCRIPTS) $(SCRIPTS_NX) $(UDEV_RULES)

install: all
	mkdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(RULESDIR)"
	install -m$(XMOD) $(SCRIPTS) "$(DESTDIR)$(SCRIPTDIR)/"
	install -m$(FMOD) $(SCRIPTS_NX) "$(DESTDIR)$(SCRIPTDIR)/"
	install -m$(FMOD) $(UDEV_RULES) "$(DESTDIR)$(RULESDIR)/"

uninstall:
	-cd "$(DESTDIR)$(SCRIPTDIR)" && rm -f $(SCRIPTS) $(SCRIPTS_NX)
	-cd "$(DESTDIR)$(RULESDIR)" && rm -f $(UDEV_RULES)
	-rmdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(RULESDIR)"

.PHONY: all clean install uninstall
