AC_PREREQ([2.60])
AC_INIT([uam], [0.3.2])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([1.6 foreign dist-bzip2 no-dependencies])

AC_PROG_SED

PKG_PROG_PKG_CONFIG

# Avoid //
if test x"$prefix" = x"/"; then
	prefix=
fi

AC_ARG_WITH([udevdir],
	AS_HELP_STRING([--with-udevdir=DIR], [the root udev install directory (LIBDIR/udev)]),
	[], [
		AC_MSG_CHECKING([where udev lives])
		with_udevdir=`$PKG_CONFIG --variable=udevdir udev`
		AC_MSG_RESULT([$with_udevdir])

		AS_IF([test x"$with_udevdir" = x""], [
			AC_MSG_ERROR([unable to get udevdir from udev.pc])
		])
	])
AC_ARG_WITH([rulesdir],
	AS_HELP_STRING([--with-rulesdir=DIR], [the udev rules.d directory (UDEVDIR/rules.d)]),
	[], [with_rulesdir=$with_udevdir/rules.d])
AC_ARG_WITH([scriptdir],
	AS_HELP_STRING([--with-scriptdir=DIR], [the directory to install scripts to (UDEVDIR/uam)]),
	[], [with_scriptdir=$with_udevdir/uam])
AC_ARG_WITH([confdir],
	AS_HELP_STRING([--with-confdir=DIR], [the script configuration directory (SYSCONFDIR/udev)]),
	[], [with_confdir=$sysconfdir/udev])
AC_ARG_WITH([hookdir],
	AS_HELP_STRING([--with-hookdir=DIR], [the uam hook directory (CONFDIR/uam-hooks)]),
	[], [with_hookdir=$with_confdir/uam-hooks])

AC_SUBST([rulesdir], [$with_rulesdir])
AC_SUBST([scriptdir], [$with_scriptdir])
AC_SUBST([confdir], [$with_confdir])
AC_SUBST([hookdir], [$with_hookdir])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
