# Below variables are to be modified or overriden

DESTDIR		= 
SCRIPTDIR	= /lib/udev/uam
CONFIGDIR	= /etc/udev
RULESDIR	= /etc/udev/rules.d

# End of simple config, you shall not pass below

BUILDDIR	= build
SRCDIR		= src

SCRIPTS_NX	= array.awk mounts.awk
CONFIG		= uam.conf

XMOD		= 0700
FMOD		= 0600

all:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) \
		SCRIPTDIR="$(SCRIPTDIR)" CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)"

clean:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) clean

install:
	cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" XMOD=$(XMOD) FMOD=$(FMOD) \
		SCRIPTDIR="$(SCRIPTDIR)" CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)" install
	mkdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)"
	cd "$(SRCDIR)" && install -m$(FMOD) $(SCRIPTS_NX) "$(DESTDIR)$(SCRIPTDIR)/"
	[ -f "$(DESTDIR)$(CONFIGDIR)/$(CONFIG)" ] || install -m$(FMOD) $(CONFIG) "$(DESTDIR)$(CONFIGDIR)/"

uninstall:
	-cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" \
		SCRIPTDIR="$(SCRIPTDIR)" RULESDIR="$(RULESDIR)" uninstall
	-cd "$(DESTDIR)$(SCRIPTDIR)" && rm -f $(SCRIPTS_NX)
	-rmdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)"

.PHONY: all clean install uninstall
