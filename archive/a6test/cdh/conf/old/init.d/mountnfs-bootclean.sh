#! /bin/sh
### BEGIN INIT INFO
# Provides:          mountnfs-bootclean
# Required-Start:    $local_fs mountnfs
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# X-Start-Before:    bootmisc
# Short-Description: bootclean after mountnfs.
# Description:       Clean temporary filesystems after
#                    network filesystems have been mounted.
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
	echo "Usage: mountnfs-bootclean.sh [start|stop]" >&2
	exit 3
	;;
esac

:
