DESTDIR		= 
SCRIPTDIR	= /lib/udev/uam
CONFIGDIR	= /etc/udev
RULESDIR	= /etc/udev/rules.d

SRCDIR		= src
SCRIPTS		= uam-mount.sh uam-umount.sh find-helper.sh
SCRIPTS_NX	= uam-common.sh array.awk
UDEV_RULES	= 10-uam.rules
CONFIG		= uam.conf

all:

clean:

install:
	mkdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)" "$(DESTDIR)$(RULESDIR)"
	cd "$(SRCDIR)" && install -m700 $(SCRIPTS) "$(DESTDIR)$(SCRIPTDIR)/"
	cd "$(SRCDIR)" && install -m600 $(SCRIPTS_NX) "$(DESTDIR)$(SCRIPTDIR)/"
	install -m600 $(UDEV_RULES) "$(DESTDIR)$(RULESDIR)/"
	install -m600 $(CONFIG) "$(DESTDIR)$(CONFIGDIR)/"

uninstall:
	cd "$(DESTDIR)$(SCRIPTDIR)" && rm -f $(SCRIPTS) $(SCRIPTS_NX)
	cd "$(DESTDIR)$(RULESDIR)" && rm -f $(UDEV_RULES)
	cd "$(DESTDIR)$(CONFIGDIR)" && rm -f $(CONFIG)
	-rmdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)" "$(DESTDIR)$(RULESDIR)"

.PHONY: all clean install uninstall
