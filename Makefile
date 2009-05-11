
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
	true

clean:
	true

install:
	mkdir -p $(DESTDIR)$(SCRIPTDIR) $(DESTDIR)$(CONFIGDIR) $(DESTDIR)$(RULESDIR)
	install -m700 $(addprefix $(SRCDIR)/,$(SCRIPTS)) $(DESTDIR)$(SCRIPTDIR)/
	install -m600 $(addprefix $(SRCDIR)/,$(SCRIPTS_NX)) $(DESTDIR)$(SCRIPTDIR)/
	install -m600 $(UDEV_RULES) $(DESTDIR)$(RULESDIR)/
	install -m600 $(CONFIG) $(DESTDIR)$(CONFIGDIR)/

uninstall:
	rm -f $(addprefix $(DESTDIR)$(SCRIPTDIR)/,$(SCRIPTS) $(SCRIPTS_NX))
	rm -f $(addprefix $(DESTDIR)$(RULESDIR)/,$(UDEV_RULES))
	rm -f $(addprefix $(DESTDIR)$(CONFIGDIR)/,$(CONFIG))
	rmdir -p --ignore-fail-on-non-empty $(DESTDIR)$(SCRIPTDIR) $(DESTDIR)$(CONFIGDIR) $(DESTDIR)$(RULESDIR)

.PHONY: all clean install uninstall
