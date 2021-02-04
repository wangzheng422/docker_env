#! /bin/sh
### BEGIN INIT INFO
# Provides:          mountall
# Required-Start:    checkfs checkroot-bootclean
# Required-Stop: 
# Default-Start:     S
# Default-Stop:
# Short-Description: Mount all filesystems.
# Description:
### END INIT INFO

PATH=/sbin:/bin
. /lib/lsb/init-functions
. /lib/init/vars.sh
. /lib/init/tmpfs.sh

. /lib/init/mount-functions.sh
. /lib/init/swap-functions.sh

# for ntfs-3g to get correct file name encoding
if [ -r /etc/default/locale ]; then
	. /etc/default/locale
	export LANG
fi

do_start() {
	#
	# Mount local file systems in /etc/fstab.
	#
	mount_all_local() {
		if mountpoint -q /usr; then
			# May have been mounted read-only by initramfs.
			# Remount with unmodified options from /etc/fstab.
			mount -o remount /usr
		fi
		mount -a -t nonfs,nfs4,smbfs,cifs,ncp,ncpfs,coda,ocfs2,gfs,gfs2,ceph \
			-O no_netdev
	}
	pre_mountall
	if [ "$VERBOSE" = no ]
	then
		log_action_begin_msg "Mounting local filesystems"
		mount_all_local
		log_action_end_msg $?
	else
		log_daemon_msg "Will now mount local filesystems"
		mount_all_local
		log_end_msg $?
	fi
	post_mountall

	# We might have mounted something over /run; see if
	# /run/initctl is present.  Look for
	# /usr/share/sysvinit/update-rc.d to verify that sysvinit (and
	# not upstart) is installed).
	INITCTL="/run/initctl"
	if [ ! -p "$INITCTL" ] && [ -f "/usr/share/sysvinit/update-rc.d" ]; then
		# Create new control channel
		rm -f "$INITCTL"
		mknod -m 600 "$INITCTL" p

		# Reopen control channel.
		PID="$(pidof -s /sbin/init || echo 1)"
		[ -n "$PID" ] && kill -s USR1 "$PID"
	fi

	# Execute swapon command again, in case we want to swap to
	# a file on a now mounted filesystem.
	swaponagain 'swapfile'

	# Remount tmpfs filesystems; with increased VM after swapon,
	# the size limits may be adjusted.
	mount_run mount_noupdate
	mount_lock mount_noupdate
	mount_shm mount_noupdate

	# Now we have mounted everything, check whether we need to
	# mount a tmpfs on /tmp.  We can now also determine swap size
	# to factor this into our size limit.
	mount_tmp mount_noupdate
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
	echo "Usage: mountall.sh [start|stop]" >&2
	exit 3
	;;
esac

:
