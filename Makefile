# Below variables are to be modified or overriden

DESTDIR		= 
SCRIPTDIR	= /lib/udev/uam
CONFIGDIR	= /etc/udev
RULESDIR	= /etc/udev/rules.d

# End of simple config, you shall not pass below

VERSION		= 0.0.2_p1

BUILDDIR	= build
SRCDIR		= src

SCRIPTS_NX	= array.awk mounts.awk
CONFIG		= uam.conf

XMOD		= 0700
FMOD		= 0600
DMASK		= 0077

all:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) VERSION="$(VERSION)" \
		SCRIPTDIR="$(SCRIPTDIR)" CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)"

clean:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) clean

install:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" XMOD=$(XMOD) \
		FMOD=$(FMOD) DMASK=$(DMASK) SCRIPTDIR="$(SCRIPTDIR)" \
		CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)" install
	umask $(DMASK); mkdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)"
	cd "$(SRCDIR)" && cp $(SCRIPTS_NX) "$(DESTDIR)$(SCRIPTDIR)/"
	cd "$(DESTDIR)$(SCRIPTDIR)" && chmod $(FMOD) $(SCRIPTS_NX)
	[ -f "$(DESTDIR)$(CONFIGDIR)/$(CONFIG)" ] || cp $(CONFIG) "$(DESTDIR)$(CONFIGDIR)/"
	cd "$(DESTDIR)$(CONFIGDIR)" && chmod $(FMOD) $(CONFIG)

uninstall:
	-cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" \
		SCRIPTDIR="$(SCRIPTDIR)" RULESDIR="$(RULESDIR)" uninstall
	-cd "$(DESTDIR)$(SCRIPTDIR)" && rm -f $(SCRIPTS_NX)
	-rmdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)"

.PHONY: all clean install uninstall
