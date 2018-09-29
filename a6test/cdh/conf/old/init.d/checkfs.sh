#! /bin/sh
### BEGIN INIT INFO
# Provides:          checkfs
# Required-Start:    checkroot
# Required-Stop:
# Should-Start:
# Default-Start:     S
# Default-Stop:
# X-Interactive:     true
# Short-Description: Check all filesystems.
### END INIT INFO

# Include /usr/bin in path to find on_ac_power if /usr/ is on the root
# partition.
PATH=/sbin:/bin:/usr/bin
FSCK_LOGFILE=/var/log/fsck/checkfs
[ "$FSCKFIX" ] || FSCKFIX=no
. /lib/init/vars.sh

. /lib/lsb/init-functions
. /lib/init/mount-functions.sh
. /lib/init/swap-functions.sh

do_start () {
	# Trap SIGINT so that we can handle user interupt of fsck.
	trap "" INT

	# See if we're on AC Power.  If not, we're not gonna run our
	# check.  If on_ac_power (in /usr/) is unavailable, behave as
	# before and check all file systems needing it.

# Disabled AC power check until fsck can be told to only check the
# file system if it is corrupt when running on battery. (bug #526398)
#	if which on_ac_power >/dev/null 2>&1
#	then
#		on_ac_power >/dev/null 2>&1
#		if [ $? -eq 1 ]
#		then
#			[ "$VERBOSE" = no ] || log_success_msg "Running on battery power, so skipping file system check."
#			BAT=yes
#		fi
#	fi
	BAT=""
	fscheck="yes"

	if is_fastboot_active
	then
		[ "$fscheck" = yes ] && log_warning_msg "Fast boot enabled, so skipping file system check."
		fscheck=no
	fi

	#
	# Check the rest of the file systems.
	#
	if [ "$fscheck" = yes ] && [ ! "$BAT" ] && [ "$FSCKTYPES" != "none" ]
	then

		# Execute swapon command again, in case there are lvm
		# or md swap partitions.  fsck can suck RAM.
		swaponagain 'lvm and md'

		if [ -f /forcefsck ] || grep -q -s -w -i "forcefsck" /proc/cmdline
		then
			force="-f"
		else
			force=""
		fi
		if [ "$FSCKFIX" = yes ]
		then
			fix="-y"
		else
			fix="-a"
		fi
		spinner="-C"
		case "$TERM" in
		  dumb|network|unknown|"")
			spinner=""
			;;
		esac
		[ "$(uname -m)" = s390x ] && spinner=""  # This should go away
		FSCKTYPES_OPT=""
		[ "$FSCKTYPES" ] && FSCKTYPES_OPT="-t $FSCKTYPES"
		handle_failed_fsck() {
			log_failure_msg "File system check failed. 
A log is being saved in ${FSCK_LOGFILE} if that location is writable. 
Please repair the file system manually."
			log_warning_msg "A maintenance shell will now be started. 
CONTROL-D will terminate this shell and resume system boot."
			# Start a single user shell on the console
			if ! sulogin $CONSOLE
			then
				log_failure_msg "Attempt to start maintenance shell failed. 
Continuing with system boot in 5 seconds."
				sleep 5
			fi
		}
		if [ "$VERBOSE" = no ]
		then
			log_action_begin_msg "Checking file systems"
			logsave -s $FSCK_LOGFILE fsck $spinner -M -A $fix $force $FSCKTYPES_OPT
			FSCKCODE=$?

			if [ "$FSCKCODE" -eq 32 ]
			then
				log_action_end_msg 1 "code $FSCKCODE"
				log_warning_msg "File system check was interrupted by user"
			elif [ "$FSCKCODE" -gt 1 ]
			then
				log_action_end_msg 1 "code $FSCKCODE"
				handle_failed_fsck
			else
				log_action_end_msg 0
			fi
		else
			if [ "$FSCKTYPES" ]
			then
				log_action_msg "Will now check all file systems of types $FSCKTYPES"
			else
				log_action_msg "Will now check all file systems"
			fi
			logsave -s $FSCK_LOGFILE fsck $spinner -V -M -A $fix $force $FSCKTYPES_OPT
			FSCKCODE=$?
			if [ "$FSCKCODE" -eq 32 ]
			then
				log_warning_msg "File system check was interrupted by user"
			elif [ "$FSCKCODE" -gt 1 ]
			then
				handle_failed_fsck
			else
				log_success_msg "Done checking file systems. 
A log is being saved in ${FSCK_LOGFILE} if that location is writable."
			fi
		fi
	fi
	rm -f /fastboot /forcefsck 2>/dev/null
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
	echo "Usage: checkfs.sh [start|stop]" >&2
	exit 3
	;;
esac

:
