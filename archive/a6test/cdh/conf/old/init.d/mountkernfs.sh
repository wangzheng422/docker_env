#! /bin/sh
### BEGIN INIT INFO
# Provides:          mountkernfs
# Required-Start:
# Required-Stop:
# Should-Start:      glibc
# Default-Start:     S
# Default-Stop:
# Short-Description: Mount kernel virtual file systems.
# Description:       Mount initial set of virtual filesystems the kernel
#                    provides and that are required by everything.
### END INIT INFO

PATH=/sbin:/bin
. /lib/lsb/init-functions
. /lib/init/vars.sh
. /lib/init/tmpfs.sh

. /lib/init/mount-functions.sh

# May be run several times, so must be idempotent.
# $1: Mount mode, to allow for remounting
mount_filesystems () {
	MNTMODE="$1"

	#
	# Mount tmpfs on /run and/or /run/lock
	#
	mount_run "$MNTMODE"
	mount_lock "$MNTMODE"

	#
	# Mount proc filesystem on /proc
	#
	domount "$MNTMODE" proc "" /proc proc "-onodev,noexec,nosuid"

	#
	# Mount sysfs on /sys
	#
	# Only mount sysfs if it is supported (kernel >= 2.6)
	if grep -E -qs "sysfs\$" /proc/filesystems
	then
		domount "$MNTMODE" sysfs "" /sys sysfs "-onodev,noexec,nosuid"
	fi

	if [ -d /sys/fs/pstore ]
	then
		domount "$MNTMODE" pstore "" /sys/fs/pstore pstore ""
	fi

	if [ -d /sys/kernel/config ]
	then
		domount "$MNTMODE" configfs "" /sys/kernel/config configfs ""
	fi
}

case "$1" in
  "")
	echo "Warning: mountkernfs should be called with the 'start' argument." >&2
	mount_filesystems mount_noupdate
	;;
  start)
	mount_filesystems mount_noupdate
	;;
  restart|reload|force-reload)
	mount_filesystems remount
	;;
  stop|status)
	# No-op
	;;
  *)
	echo "Usage: mountkernfs [start|stop]" >&2
	exit 3
	;;
esac
