# rhel8 prepare

```bash
# Activate the web console with: 
systemctl enable --now cockpit.socket

# This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
# To register this system, run: 
insights-client --register

subscription-manager config --rhsm.baseurl=https://china.cdn.redhat.com

subscription-manager --proxy=192.168.253.1:5084 register --username **** --password ********

# go to https://access.redhat.com/management/system to add subscription,
# or add here using cli
subscription-manager --proxy=192.168.253.1:5084 list --available --all
subscription-manager --proxy=192.168.253.1:5084 attach --pool=8a85f99a6fa01382016fc16b7c045e16

subscription-manager --proxy=192.168.253.1:5084 repos --list > list
subscription-manager --proxy=192.168.253.1:5084 repos --list-enabled

subscription-manager --proxy=192.168.253.1:5084 repos --disable="*"

# subscription-manager --proxy=192.168.253.1:5084 refresh

subscription-manager --proxy=192.168.253.1:5084 repos \
    --enable="rhel-8-for-x86_64-baseos-rpms" \
    --enable="rhel-8-for-x86_64-baseos-source-rpms" \
    --enable="rhel-8-for-x86_64-appstream-rpms" \
    --enable="rhel-8-for-x86_64-supplementary-rpms" \
    --enable="codeready-builder-for-rhel-8-x86_64-rpms" \
    --enable="rhel-8-for-x86_64-rt-rpms" \
    --enable="rhel-8-for-x86_64-highavailability-rpms" \
    --enable="rhel-8-for-x86_64-nfv-rpms" \
    --enable="cnv-2.5-for-rhel-8-x86_64-rpms" \
    --enable="rhocp-4.6-for-rhel-8-x86_64-rpms" \
    --enable="fast-datapath-for-rhel-8-x86_64-rpms" \
    --enable="ansible-2.9-for-rhel-8-x86_64-rpms" \
    # ansible-2.9-for-rhel-8-x86_64-rpms

    # --enable="rhv-4-mgmt-agent-for-rhel-8-x86_64-rpms" \

dnf repolist

dnf clean all
dnf makecache

dnf -y install dnf-plugins-core
# add epel
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

cat << EOF >> /etc/dnf/dnf.conf
proxy=http://192.168.253.1:5084
EOF
cat << EOF >> /etc/dnf/dnf.conf
fastestmirror=1
EOF

dnf install htop byobu

# gpu
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&target_distro=RHEL&target_version=8&target_type=rpmnetwork
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
sudo dnf clean all
# sudo dnf -y module install nvidia-driver:latest-dkms
# sudo dnf -y install cuda

# https://nvidia.github.io/nvidia-container-runtime/
dnf repolist
dnf clean all
dnf makecache


# https://access.redhat.com/solutions/3755871
# dnf install /usr/bin/reposync

# reposync -q -n --repo rhel-8-for-x86_64-appstream-rpms -p /repositories --downloadcomps --download-metadata

mkdir -p /data/dnf
cd /data/dnf

dnf reposync -m --download-metadata --delete -n

cd /data
tar -cvf - dnf/ | pigz -c > /mnt/hgfs/ocp/rhel-dnf-8.2.tgz

```