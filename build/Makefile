SRCDIR		= ../src

SCRIPTS		= uam-mount.sh uam-umount.sh find-helper.sh

all: $(SCRIPTS)
	@true

%.sh:
	sed -e ''\
		"$(SRCDIR)/$@" > "$@"

clean:
	rm -f $(SCRIPTS)

install: all
	mkdir -p "$(DESTDIR)$(SCRIPTDIR)"
	install -m$(XMOD) $(SCRIPTS) "$(DESTDIR)$(SCRIPTDIR)/"

uninstall:
	cd "$(DESTDIR)$(SCRIPTDIR)" && rm -f $(SCRIPTS)

.PHONY: all clean install uninstall
