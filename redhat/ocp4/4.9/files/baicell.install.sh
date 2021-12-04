BASE_DIR=$(cd "$(dirname "$0")"; pwd); cd ${BASE_DIR}
SCRIPT_DIR=$BASE_DIR/scripts
RPM_DIR=$BASE_DIR/files
SLEEP_SEC=10

######### Variable ##########
CURRENT_USER="$(id -un 2>/dev/null || true)"
BASH_C="bash -c"

######### Constant ##########
SUPPORT_DISTRO=(centos)
CENTOS_VER=(7.4)

# Error Message
ERR_ROOT_PRIVILEGE_REQUIRED="This install script need root privilege, please retry use 'sudo' or root user!"
ERR_NOT_SUPPORT_PLATFORM="Sorry, FlexRAN only support x86_64 platform!"

# Color Constant
RED=`tput setaf 1 || true`
GREEN=`tput setaf 2 || true`
YELLOW=`tput setaf 3 || true`
BLUE=`tput setaf 4 || true`
WHITE=`tput setaf 7 || true`
LIGHT=`tput bold || true`
RESET=`tput sgr0 || true`

######### Function Definition ##########
i_base() {
  log info "Welcome to Install Baicells FlexRAN...\n"
  check_system
  install_common_deps
}

check_system() {
  log info "1. check user"
  check_user
  log done "check user...done"

  log info "2. check os platform"
  check_os_platform
  log done "check os platform...done"
}

check_user() {
  if [[ "${CURRENT_USER}" != "root" ]];then
    if (command_exist sudo);then
      BASH_C="sudo -E bash -c"
    else
      log error "$ERR_ROOT_PRIVILEGE_REQUIRED"
    fi
    log info "${WHITE}Hint: FlexRAN installer need root privilege\n"
    ${BASH_C} "echo -n"
  fi
}

check_os_platform() {
  ARCH="$(uname -m)"
  if [[ "${ARCH}" != "x86_64" ]];then
    log error "$ERR_NOT_SUPPORT_PLATFORM}"
  fi
}


yum_install() {
    for pkg in $@; do
        rpm -q $pkg > /dev/null || yum install -y -q $pkg || true
    done
}

log_start() {
  log info "install $1"
}

log_end() {
  log done "install $1...done"
}

clean() {
  rm -rf $TMP_DIR
}

start_service() {
  systemctl enable $1 && systemctl restart $1 && systemctl status $1 || true
}

command_exist() {
  type "$@" > /dev/null 2>&1
}

log() {
  case "$1" in
    debug)		echo -e "[${BLUE}DEBUG${RESET}] : $2\n";;
    info)		echo -e -n "${WHITE}$2${RESET}\n" ;;
    warn)		echo -e    "[${YELLOW}WARN${RESET}] : $2\n" ;;
    done|success)	echo -e "${LIGHT}${GREEN}$2${RESET}\n\n" ;;
    error|failure)	echo -e "[${RED}ERROR${RESET}] : $2\n" && exit 1 ;;
  esac
}

install_common_deps() {
  log info "4. install common deps"
  rm -rf /var/cache/yum/ || true
  yum install numa* -y
  yum install tuna  -y
  yum install libhugetlbfs -y
  yum install -y gcc-c++ libcgroup
  log done "install common deps...done"
}


i_rt_linux() {
  log_start rt_linux
  source $SCRIPT_DIR/install_rt.sh || true

  log_end rt
}

i_lib() {
  log_start libs
  source $SCRIPT_DIR/install_lib.sh || true
}


i_all() {
  i_base || true
  log info "5. install"
  i_rt_linux || true
  i_lib || true
  log info "install...done"
}

usage() {
    cat << EOF
NAME
    install.sh - Install Baicells FlexRAN

SYNOPSIS
    $prog COMMAND [OPTIONS]

DESCRIPTION
    A tool to install Baicells FlexRAN, inclue Phy

OPTIONS
    -h        Show this help
    -i        Service to install   (default: all)

EOF
exit 0
}


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

ctrl_c() {
  echo "** CTRL-C **"
  exit 1
}


SERVICE=all
while getopts ":i:h" opt
do
  case "$opt" in
    h ) usage ;;
    i ) SERVICE=${OPTARG} ;;
    * ) usage ;;
  esac
done
case "$SERVICE" in
  base)
    i_base
    ;;
  rt)
    i_rt_linux
    ;;
  lib)
    i_lib
    ;;
  all)
    i_all
    ;;
  *)
    usage
    ;;
esac

# install rec lib
cp $BASE_DIR/rec/libnr.so.0.0.1  /usr/lib64/
ln -sf  /usr/lib64/libnr.so.0.0.1  /usr/lib64/libnr.so
ln -sf  /usr/lib64/libnr.so.0.0.1  /usr/lib64/libnr.so.0

# install wls lib

cp $BASE_DIR/wls_mod/libwls.so /usr/lib64

# install dpdk huge
echo GRUB_CMDLINE_LINUX=\"crashkernel=auto rd.lvm.lv=centos/root rd.lvm.lv=centos/swap no_timer_check clocksource=tsc tsc=perfect intel_pstate=disable selinux=0 enforcing=0 nmi_watchdog=0 softlockup_panic=0 isolcpus=1-39 nohz_full=0-39 idle=poll default_hugepagesz=1G hugepagesz=1G hugepages=16 rcu_nocbs=1-39 kthread_cpus=0 irqaffinity=0 rcu_nocb_poll rhgb quiet\" >> /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# install icc lib
cp $RPM_DIR/lib/libimf.so  /usr/lib64/
cp $RPM_DIR/lib/libintlc.so*  /usr/lib64/
cp $RPM_DIR/lib/libsvml.so  /usr/lib64/
cp $RPM_DIR/lib/libirng.so  /usr/lib64/


