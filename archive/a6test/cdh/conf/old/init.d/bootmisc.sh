#!/bin/sh
### BEGIN INIT INFO
# Provides:          bootmisc
# Required-Start:    $remote_fs
# Required-Stop:
# Should-Start:      udev
# Default-Start:     S
# Default-Stop:
# Short-Description: Miscellaneous things to be done during bootup.
# Description:       Some cleanup.  Note, it need to run after mountnfs-bootclean.sh.
### END INIT INFO

. /lib/lsb/init-functions

PATH=/sbin:/usr/sbin:/bin:/usr/bin
[ "$DELAYLOGIN" ] || DELAYLOGIN=yes
. /lib/init/vars.sh

do_start () {
	#
	# If login delaying is enabled then create the flag file
	# which prevents logins before startup is complete
	#
	case "$DELAYLOGIN" in
	  Y*|y*)
		echo "System bootup in progress - please wait" > /var/lib/initscripts/nologin
		;;
	esac

	# Create /var/run/utmp so we can login.
	: > /var/run/utmp
	if grep -q ^utmp: /etc/group
	then
		chmod 664 /var/run/utmp
		chgrp utmp /var/run/utmp
	fi

	# Remove bootclean's flag files.
	# Don't run bootclean again after this!
	rm -f /tmp/.clean /run/.clean /run/lock/.clean
	rm -f /tmp/.tmpfs /run/.tmpfs /run/lock/.tmpfs
}

case "$1" in
  start|"")
	do_start
	;;
  restart|reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  stop|status)
	# No-op
	;;
  *)
	echo "Usage: bootmisc.sh [start|stop]" >&2
	exit 3
	;;
esac

:
