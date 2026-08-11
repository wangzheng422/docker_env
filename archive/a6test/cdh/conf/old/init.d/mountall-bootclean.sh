#! /bin/sh
### BEGIN INIT INFO
# Provides:          mountall-bootclean
# Required-Start:    mountall
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# X-Start-Before:    bootmisc
# Short-Description: bootclean after mountall.
# Description:       Clean temporary filesystems after
#                    all local filesystems have been mounted.
### END INIT INFO

. /lib/lsb/init-functions
. /lib/init/bootclean.sh

case "$1" in
  start|"")
	# Clean /tmp, /var/lock, /var/run
	clean_all
	exit $?
	;;
  restart|reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  stop|status)
	# No-op
	;;
  *)
	echo "Usage: mountall-bootclean.sh [start|stop]" >&2
	exit 3
	;;
esac

:
