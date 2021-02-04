TARGETS = mountkernfs.sh hostname.sh x11-common mountdevsubfs.sh procps hwclock.sh checkroot.sh urandom networking mountall.sh checkfs.sh checkroot-bootclean.sh bootmisc.sh mountall-bootclean.sh mountnfs.sh mountnfs-bootclean.sh
INTERACTIVE = checkroot.sh checkfs.sh
mountdevsubfs.sh: mountkernfs.sh
procps: mountkernfs.sh
hwclock.sh: mountdevsubfs.sh
checkroot.sh: hwclock.sh mountdevsubfs.sh hostname.sh
urandom: hwclock.sh
networking: mountkernfs.sh urandom procps
mountall.sh: checkfs.sh checkroot-bootclean.sh
checkfs.sh: checkroot.sh
checkroot-bootclean.sh: checkroot.sh
bootmisc.sh: checkroot-bootclean.sh mountall-bootclean.sh mountnfs-bootclean.sh
mountall-bootclean.sh: mountall.sh
mountnfs.sh: networking
mountnfs-bootclean.sh: mountnfs.sh
