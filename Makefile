
DESTDIR		= 
SCRIPTDIR	= /lib/udev/uam
CONFIGDIR	= /etc/udev
RULESDIR	= /etc/udev/rules.d

SCRIPTS		= uam-mount.sh uam-umount.sh
SCRIPTS_NX	= uam-common.sh array.awk
UDEV_RULES	= 10-uam.rules
CONFIG		= uam.conf

all:
	true

clean:
	true

install:
	mkdir -p $(DESTDIR)$(SCRIPTDIR) $(DESTDIR)$(CONFIGDIR) $(DESTDIR)$(RULESDIR)
	install -m700 $(SCRIPTS) $(DESTDIR)$(SCRIPTDIR)/
	install -m600 $(SCRIPTS_NX) $(DESTDIR)$(SCRIPTDIR)/
	install -m600 $(UDEV_RULES) $(DESTDIR)$(RULESDIR)/
	install -m600 $(CONFIG) $(DESTDIR)$(CONFIGDIR)/

uninstall:
	rm -f $(addprefix $(DESTDIR)$(SCRIPTDIR)/,$(SCRIPTS) $(SCRIPTS_NX))
	rm -f $(addprefix $(DESTDIR)$(RULESDIR)/,$(UDEV_RULES))
	rm -f $(addprefix $(DESTDIR)$(CONFIGDIR)/,$(CONFIG))
	rmdir -p --ignore-fail-on-non-empty $(DESTDIR)$(SCRIPTDIR) $(DESTDIR)$(CONFIGDIR) $(DESTDIR)$(RULESDIR)

.PHONY: all clean install uninstall
