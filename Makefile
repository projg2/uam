# Below variables are to be modified or overriden

DESTDIR		= 
LIBDIR		= /lib
SCRIPTDIR	= $(LIBDIR)/udev/uam
CONFIGDIR	= /etc/udev
HOOKDIR		= $(CONFIGDIR)/uam-hooks
RULESDIR	= /etc/udev/rules.d

# End of simple config, you shall not pass below

VERSION		= 0.0.5

BUILDDIR	= build
SRCDIR		= src
SRCHOOKDIR	= uam-hooks

SCRIPTS_NX	= array.awk mounts.awk
CONFIG		= uam.conf
HOOK_DIRS	= pre-mount post-mount mount-failed pre-umount post-umount
HOOK_POSTM	= 90_sw_notify
HOOK_POSTU	= 90_sw_notify
HOOK_MFAIL	= 90_sw_notify

XMOD		= 0755
FMOD		= 0644
DMASK		= 0022

all:
	+cd "$(BUILDDIR)" && make $(MAKEFLAGS) VERSION="$(VERSION)" LIBDIR="$(LIBDIR)" \
		SCRIPTDIR="$(SCRIPTDIR)" CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)" \
		HOOKDIR="$(HOOKDIR)"

clean:
	+cd "$(BUILDDIR)" && make $(MAKEFLAGS) clean

install:
	+cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" XMOD=$(XMOD) \
		FMOD=$(FMOD) DMASK=$(DMASK) SCRIPTDIR="$(SCRIPTDIR)" \
		CONFIGDIR="$(CONFIGDIR)" RULESDIR="$(RULESDIR)" install
	umask $(DMASK); mkdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)"; \
		for _dir in $(HOOK_DIRS); do mkdir -p "$(DESTDIR)$(HOOKDIR)"/$${_dir}; done
	cd "$(SRCDIR)" && cp $(SCRIPTS_NX) "$(DESTDIR)$(SCRIPTDIR)/"
	
	cd "$(SRCHOOKDIR)"/post-mount && cp $(HOOK_POSTM) "$(DESTDIR)$(HOOKDIR)"/post-mount/
	cd "$(SRCHOOKDIR)"/post-umount && cp $(HOOK_POSTU) "$(DESTDIR)$(HOOKDIR)"/post-umount/
	cd "$(SRCHOOKDIR)"/mount-failed && cp $(HOOK_MFAIL) "$(DESTDIR)$(HOOKDIR)"/mount-failed/

	cd "$(DESTDIR)$(SCRIPTDIR)" && chmod $(FMOD) $(SCRIPTS_NX)
	[ -f "$(DESTDIR)$(CONFIGDIR)/$(CONFIG)" ] || cp $(CONFIG) "$(DESTDIR)$(CONFIGDIR)/"
	cd "$(DESTDIR)$(CONFIGDIR)" && chmod $(FMOD) $(CONFIG)

	cd "$(DESTDIR)$(HOOKDIR)"/post-mount && chmod $(FMOD) $(HOOK_POSTM)
	cd "$(DESTDIR)$(HOOKDIR)"/post-umount && chmod $(FMOD) $(HOOK_POSTU)
	cd "$(DESTDIR)$(HOOKDIR)"/mount-failed && chmod $(FMOD) $(HOOK_MFAIL)

uninstall:
	-+cd "$(BUILDDIR)" && make $(MAKEFLAGS) DESTDIR="$(DESTDIR)" \
		SCRIPTDIR="$(SCRIPTDIR)" RULESDIR="$(RULESDIR)" uninstall
	-cd "$(DESTDIR)$(SCRIPTDIR)" && rm -f $(SCRIPTS_NX)
	-rmdir -p "$(DESTDIR)$(SCRIPTDIR)" "$(DESTDIR)$(CONFIGDIR)"
	-for _dir in $(HOOK_DIRS); do rmdir -p "$(DESTDIR)$(HOOKDIR)"/$${_dir}; done

.PHONY: all clean install uninstall
