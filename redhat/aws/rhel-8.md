# rhel8 prepare

```bash
# https://access.redhat.com/solutions/3755871
dnf install /usr/bin/reposync

reposync -q -n --repo rhel-8-for-x86_64-appstream-rpms -p /repositories --downloadcomps --download-metadata

# add epel
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# gpu
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&target_distro=RHEL&target_version=8&target_type=rpmnetwork
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
sudo dnf clean all
# sudo dnf -y module install nvidia-driver:latest-dkms
# sudo dnf -y install cuda

# https://nvidia.github.io/nvidia-container-runtime/

```