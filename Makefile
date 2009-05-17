DESTDIR		= /tmp/test
SCRIPTDIR	= /lib/udev/uam
CONFIGDIR	= /etc/udev
RULESDIR	= /etc/udev/rules.d

BUILDDIR	= build
SRCDIR		= src

SCRIPTS_NX	= uam-common.sh array.awk
UDEV_RULES	= 10-uam.rules
CONFIG		= uam.conf

XMOD		= 0700
FMOD		= 0600

all:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) \
		SCRIPTDIR="$(SCRIPTDIR)" CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)"

clean:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) clean

install:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" XMOD="$(XMOD)" \
		SCRIPTDIR="$(SCRIPTDIR)" CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)" install
	mkdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)" "$(DESTDIR)$(RULESDIR)"
	cd "$(SRCDIR)" && install -m$(FMOD) $(SCRIPTS_NX) "$(DESTDIR)$(SCRIPTDIR)/"
	install -m$(FMOD) $(UDEV_RULES) "$(DESTDIR)$(RULESDIR)/"
	[ -f "$(DESTDIR)$(CONFIGDIR)/$(CONFIG)" ] || install -m$(FMOD) $(CONFIG) "$(DESTDIR)$(CONFIGDIR)/"

uninstall:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" \
		SCRIPTDIR="$(SCRIPTDIR)"  uninstall
	cd "$(DESTDIR)$(SCRIPTDIR)" && rm -f $(SCRIPTS_NX)
	cd "$(DESTDIR)$(RULESDIR)" && rm -f $(UDEV_RULES)
	-rmdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)" "$(DESTDIR)$(RULESDIR)"

.PHONY: all clean install uninstall
