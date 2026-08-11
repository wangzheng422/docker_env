#! /bin/sh
### BEGIN INIT INFO
# Provides:          checkroot-bootclean
# Required-Start:    checkroot
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# X-Start-Before:    bootmisc
# Short-Description: bootclean after checkroot.
# Description:       Clean temporary filesystems after
#                    the root filesystem has been mounted.
#                    At this point, directories which may be
#                    masked by future mounts may be cleaned.
### END INIT INFO

. /lib/lsb/init-functions
. /lib/init/bootclean.sh

case "$1" in
  start|"")
	# Clean /tmp, /run and /run/lock.  Remove the .clean files to
	# force initial cleaning.  This is intended to allow cleaning
	# of directories masked by mounts while the system was
	# previously running, which would otherwise prevent them being
	# cleaned.
	rm -f /tmp/.clean /run/.clean /run/lock/.clean

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
	echo "Usage: checkroot-bootclean.sh [start|stop]" >&2
	exit 3
	;;
esac

:
