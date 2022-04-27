# FROM registry.access.redhat.com/ubi8/ubi:8.4 as build

# RUN mkdir -p /opt/build && mkdir -p /opt/dist

# # install cmake
# RUN cd /opt/build && \
#     curl -LO https://github.com/Kitware/CMake/releases/download/v3.20.2/cmake-3.20.2-linux-x86_64.sh && \
#     mkdir -p /opt/dist//usr/local && \
#     /bin/bash cmake-3.20.2-linux-x86_64.sh --prefix=/opt/dist//usr/local --skip-license

FROM registry.access.redhat.com/ubi8/ubi:8.4

# COPY --from=build /opt/dist /

RUN echo -e "\
[localrepo]\n\
name=LocalRepo\n\
baseurl=ftp://45.76.69.130/dnf/\n\
enabled=1\n\
gpgcheck=0" \
> /etc/yum.repos.d/local.repo

# install OS tools
RUN dnf update -y
RUN dnf install -y make gcc gcc-c++ kernel-devel pkgconfig which bzip2

# COPY third-party-programs.txt /

# set environment variables
ENV LANG=C.UTF-8

# oneAPI repository
ARG repo=https://yum.repos.intel.com/oneapi
RUN echo -e "\
[oneAPI]\n\
name=Intel(R) oneAPI repository\n\
baseurl=${repo}\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB" \
> /etc/yum.repos.d/oneAPI.repo

# disable cert check
ARG disable_cert_check=
RUN if [ "$disable_cert_check" ] ; then echo "sslverify=false" >> /etc/yum.conf ; fi

# install Intel(R) oneAPI
RUN dnf install -y \
intel-basekit-getting-started \
intel-oneapi-advisor \
intel-oneapi-ccl-devel \
intel-oneapi-common-licensing \
intel-oneapi-common-vars \
intel-oneapi-compiler-dpcpp-cpp \
intel-oneapi-dal-devel \
intel-oneapi-dev-utilities \
intel-oneapi-dnnl-devel \
intel-oneapi-dpcpp-debugger \
intel-oneapi-ipp-devel \
intel-oneapi-ippcp-devel \
intel-oneapi-libdpstd-devel \
intel-oneapi-mkl-devel \
intel-oneapi-onevpl-devel \
intel-oneapi-python \
intel-oneapi-tbb-devel \
intel-oneapi-vtune \
--

# install Intel GPU drivers
RUN echo $'\
[intel-graphics]\n\
name=Intel Graphics Drivers Repository\n\
baseurl=https://repositories.intel.com/graphics/rhel/8.2/\n\
enabled=1\n\
gpgcheck=0' \
> /etc/yum.repos.d/intel-graphics.repo

RUN sed -i 's/^enabled=./enabled=1/' /etc/yum.repos.d/CentOS-Linux-PowerTools.repo

RUN dnf install -y \
intel-opencl \
intel-level-zero-gpu \
level-zero \
level-zero-devel

# setvars.sh environment variables
RUN env > default_env_vars; \
. /opt/intel/oneapi/setvars.sh; \
env > env_vars; \
yum install -y diffutils; \
diff default_env_vars env_vars \
| grep ">" | sed  s/..// \
| sort \
| sed 's/^/export /' | sed "s/=/='/" | sed "s/$/'/" \
>> /root/.oneapi_env_vars; \
# clean up
rm *env_vars; \
yum remove -y diffutils; \
rm -rf /var/yum/cache/*

ENTRYPOINT ["bash", "-c", "source /root/.oneapi_env_vars && \"$@\"", "bash"]