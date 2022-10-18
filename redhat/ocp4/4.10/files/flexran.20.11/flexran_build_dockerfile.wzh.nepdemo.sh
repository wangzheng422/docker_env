#!/bin/bash
local_path=$PWD
tmp_path=flexran_build
dockerimagename=flexran.docker.registry/flexran_vdu
http_proxy=`env|grep http_proxy |awk -F '=' '{print $2}'`
https_proxy=`env|grep https_proxy|awk -F '=' '{print $2}'`
rm -rf $tmp_path
# rm -rf bin/nr5g/gnb/l1/l1app
# echo "Note please first build dpdk!!!"
# source ./set_env_var.sh
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/flexran/wls_mod/lib
# ./flexran_build.sh $*
# if [ ! -f "bin/nr5g/gnb/l1/l1app" ]; then
#    echo "flexran build failed , docker image not build!!"
#    exit -1
# else
#    echo "flexran build success"
# fi
# echo "build xran"
# cd framework/bbupool/
# make clean
# make all
# cd $local_path
# cd xran
# ./build.sh xclean
# ./build.sh SAMPLEAPP

cd $local_path
mkdir $tmp_path
mkdir $tmp_path/flexran
mkdir $tmp_path/{home,intel,phy,intel.so}

cp /data/nepdemo/htop-3.0.5-1.el8.x86_64.rpm $tmp_path/

echo "copy flexran bin"
cp -r bin $tmp_path/flexran/
cp -r flexran_build.sh $tmp_path/flexran/
cp -r libs $tmp_path/flexran/
cp -r sdk $tmp_path/flexran/
#cp -r tests flexran_build/flexran/
cp -r wls_mod $tmp_path/flexran/
cp -r set_env_var.sh $tmp_path/flexran/
cp -r xran $tmp_path/flexran/
#cd flexran_build/flexran/
#add remove flexran source code
rm -rf $tmp_path/flexran/sdk/test
rm -rf $tmp_path/flexran/sdk/source
rm -rf $tmp_path/flexran/tests
rm -rf $tmp_path/flexran/source
rm -rf $tmp_path/flexran/bin/lte
rm -rf $tmp_path/flexran/libs/ferrybridge
rm -rf $tmp_path/flexran/framework
rm -rf $tmp_path/flexran/xran

echo "copy nepdemo files under home"
cp -r /data/nepdemo/flexran_cfg/* $tmp_path/flexran/bin/nr5g/gnb/l1/
cp /data/nepdemo/BaiBBU_XSS_2.0.4_oran.IMG $tmp_path/home/
cp /data/nepdemo/cfg.tar $tmp_path/home/
cp /data/nepdemo/XRAN_BBU $tmp_path/home/
cp /data/nepdemo/*.xml $tmp_path/home/
cp /opt/intel/system_studio_2019/compilers_and_libraries_2019.3.206/linux/ipp/lib/intel64/*.{so,a} $tmp_path/intel/
cp /opt/intel/system_studio_2019/compilers_and_libraries_2019.3.206/linux/mkl/lib/intel64_lin/*.so $tmp_path/intel.so/
cp /opt/intel/system_studio_2019/compilers_and_libraries_2019.3.206/linux/ipp/lib/intel64_lin/*.so $tmp_path/intel.so/
cp /opt/intel/system_studio_2019/compilers_and_libraries_2019.3.206/linux/compiler/lib/intel64_lin/*.so $tmp_path/intel.so/
/bin/cp -f /opt/intel/oneapi/compiler/2021.4.0/linux/compiler/lib/intel64_lin/*.{so,so.*} $tmp_path/intel.so/
cp -r /home/pf-bb-config $tmp_path/

cp /data/flexran/sdk/build-avx512-icc/source/phy/lib_srs_cestimate_5gnr/*.{bin,a} $tmp_path/phy/

echo 'copy for xm'
mkdir -p $tmp_path/xm/{cu_cfg,du_cfg,lib64,root,cu_bin,du_bin}
cp /data/nepdemo/xm/cu_cfg/*    $tmp_path/xm/cu_cfg/
cp /data/nepdemo/xm/du_cfg/*    $tmp_path/xm/du_cfg/
cp /data/nepdemo/xm/root/*      $tmp_path/xm/root/
cp /data/nepdemo/xm/du_bin/*    $tmp_path/xm/du_bin/
cp /data/nepdemo/xm/cu_bin/*    $tmp_path/xm/cu_bin/

#touch dockerfile
#cd $local_path

rsync --delete -arz /opt/dpdk-19.11/build $tmp_path/dpdk-19.11/
rsync --delete -arz /opt/dpdk-19.11/usertools $tmp_path/dpdk-19.11/

cat << EOF > $tmp_path/local.repo
[localrepo]
name=LocalRepo
baseurl=ftp://192.168.122.1/dnf/extensions
enabled=1
gpgcheck=0
EOF


cat << 'EOF' > $tmp_path/set_ip.sh
#!/bin/bash

# Import our environment variables from systemd
for e in $(tr "\000" "\n" < /proc/1/environ); do
  # if [[ $e == DEMO_ENV* ]]; then
    eval "export $e"
  # fi
done

echo $DEMO_ENV_NIC > /demo.txt
echo $DEMO_ENV_IP >> /demo.txt
echo $DEMO_ENV_MASK >> /demo.txt

ifconfig $DEMO_ENV_NIC:1 $DEMO_ENV_IP/$DEMO_ENV_MASK up

insmod /root/dpdk-19.11/build/kernel/linux/igb_uio/igb_uio.ko

installLic /root/13FD549D912D82B3C50C58E6D233.lic
modprobe sctp

sleep infinity

EOF

cat << EOF > $tmp_path/setip.service
[Unit]
Description=set ip service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/root/systemd/set_ip.sh

[Install]
WantedBy=multi-user.target
EOF



if [ -z $http_proxy ];then
    cat > $tmp_path/Dockerfile << 'EOF'
FROM registry.access.redhat.com/ubi8/ubi-init:8.4
# FROM registry.access.redhat.com/ubi8/ubi:8.4

RUN dnf repolist
RUN sed -i 's|enabled=1|enabled=0|g' /etc/yum/pluginconf.d/subscription-manager.conf
RUN sed -i 's|$releasever|8.4|g' /etc/yum.repos.d/redhat.repo
RUN sed -i 's|cdn.redhat.com|china.cdn.redhat.com|g' /etc/yum.repos.d/redhat.repo
RUN sed -i '/codeready-builder-for-rhel-8-x86_64-rpms/,/\[/ s/enabled = 0/enabled = 1/' /etc/yum.repos.d/redhat.repo
RUN mv -f /etc/yum.repos.d/ubi.repo /etc/yum.repos.d/ubi.repo.bak

COPY local.repo /etc/yum.repos.d/local.repo

RUN yum update -y
# RUN yum install -y libhugetlbfs-utils libhugetlbfs-devel libhugetlbfs numactl-devel pciutils libaio libaio-devel net-tools libpcap kernel-rt-core kernel-rt-devel kernel-rt-modules kernel-rt-modules-extra kernel-headers libhugetlbfs-devel zlib-devel numactl-devel

RUN yum install -y libhugetlbfs-utils libhugetlbfs-devel libhugetlbfs numactl-devel pciutils libaio libaio-devel net-tools libpcap kernel-rt-core kernel-rt-devel kernel-rt-modules kernel-rt-modules-extra kernel-headers lksctp-tools

RUN dnf install -y --allowerasing coreutils
RUN dnf groupinstall -y server
RUN dnf install -y python3 iproute kernel-tools strace openssh-clients compat-openssl10 dos2unix bc tcpdump nc iputils

COPY htop-3.0.5-1.el8.x86_64.rpm /root/tmp/
RUN dnf install -y /root/tmp/htop-3.0.5-1.el8.x86_64.rpm

WORKDIR /root/
COPY flexran ./flexran
COPY dpdk-19.11 ./dpdk-19.11
# COPY wzh/dpdk-kmods /opt/
# RUN rm -rf /var/yum/cache/*

WORKDIR /home/
COPY home/BaiBBU_XSS_2.0.4_oran.IMG ./

COPY intel/* /opt/intel/compilers_and_libraries/linux/ipp/lib/intel64/
COPY phy/* /home/bin/nr5g_img/sdk/build-avx512-icc/source/phy/lib_srs_cestimate_5gnr/

RUN tar zvxf BaiBBU_XSS_2.0.4_oran.IMG && \
    cp ./BaiBBU_XSS/tools/ImageUpgrade /bin/ && \
    ./BaiBBU_XSS/tools/ImageUpgrade /home/BaiBBU_XSS_2.0.4_oran.IMG --no-preserve 

COPY home/cfg.tar /etc/
RUN cd /etc && mv BBU_cfg bakBBU_cfg && tar zvxf cfg.tar 

COPY home/XRAN_BBU /home/BaiBBU_XSS/tools/XRAN_BBU
# COPY home/*.xml /etc/BBU_cfg/phy_cfg/

COPY intel.so/* /root/libs/
COPY pf-bb-config /root/pf-bb-config

RUN ln -s /home/BaiBBU_XSS-A/BaiBBU_DXSS/libnr_centos.so.0.0.1 /root/libs/libnr.so.0 

RUN rm -rf /opt/intel/ /home/bin/ 

ENV LD_LIBRARY_PATH=/root/libs/:/root/flexran/libs/cpa/sub6/rec/lib/lib/:/root/flexran/wls_mod/lib/:/home/BaiBBU_XSS/BaiBBU_SXSS/DU/bin:/home/BaiBBU_XSS-A/BaiBBU_SXSS/CU/lib/

COPY xm/cu_cfg/*    /etc/BBU_cfg/cu_cfg/
COPY xm/du_cfg/*    /etc/BBU_cfg/du_cfg/
COPY xm/root/*      /root/
COPY xm/du_bin/*    /home/BaiBBU_XSS/BaiBBU_SXSS/DU/bin/
COPY xm/cu_bin/*    /home/BaiBBU_XSS/BaiBBU_SXSS/CU/bin/

COPY set_ip.sh      /root/systemd/
RUN chmod +x /root/systemd/set_ip.sh   
COPY setip.service  /etc/systemd/system/setip.service
RUN systemctl enable setip.service

RUN cd /home/BaiBBU_XSS/BaiBBU_SXSS/DU/bin && ln -snf gnb_du_layer2--0422 gnb_du_layer2
RUN cd /home/BaiBBU_XSS/BaiBBU_SXSS/CU/bin && ln -snf gnb_cu_l3_no_licence gnb_cu_l3
RUN cd /root/flexran/bin/nr5g/gnb/l1/ && ln -snf l1app_1109 l1app

RUN find /root/flexran -name *.c -exec rm {} \;
RUN find /root/flexran -name *.cpp -exec rm {} \;
RUN find /root/flexran -name *.cc -exec rm {} \;
RUN find /root/flexran -name *.h -exec rm {} \;

# entrypoint ["/usr/sbin/init"]

EOF
else
    cat > $tmp_path/Dockerfile << 'EOF'
FROM registry.access.redhat.com/ubi8/ubi-init:8.4
ENV http_proxy $http_proxy
ENV https_proxy $https_proxy

RUN dnf repolist
RUN sed -i 's|enabled=1|enabled=0|g' /etc/yum/pluginconf.d/subscription-manager.conf
RUN sed -i 's|$releasever|8.4|g' /etc/yum.repos.d/redhat.repo
RUN sed -i 's|cdn.redhat.com|china.cdn.redhat.com|g' /etc/yum.repos.d/redhat.repo
RUN sed -i '/codeready-builder-for-rhel-8-x86_64-rpms/,/\[/ s/enabled = 0/enabled = 1/' /etc/yum.repos.d/redhat.repo
RUN mv -f /etc/yum.repos.d/ubi.repo /etc/yum.repos.d/ubi.repo.bak

COPY local.repo /etc/yum.repos.d/local.repo

RUN yum update -y
# RUN yum install -y libhugetlbfs-utils libhugetlbfs-devel libhugetlbfs numactl-devel pciutils libaio libaio-devel net-tools libpcap kernel-rt-core kernel-rt-devel kernel-rt-modules kernel-rt-modules-extra kernel-headers libhugetlbfs-devel zlib-devel numactl-devel cmake gcc gcc-c++
RUN yum install -y libhugetlbfs-utils libhugetlbfs-devel libhugetlbfs numactl-devel pciutils libaio libaio-devel net-tools libpcap kernel-rt-core kernel-rt-devel kernel-rt-modules kernel-rt-modules-extra kernel-headers

RUN dnf install -y --allowerasing coreutils
# RUN dnf groupinstall -y server
RUN dnf install -y python3

WORKDIR /root/
COPY flexran ./flexran
COPY dpdk-19.11 ./dpdk-19.11
# COPY wzh/dpdk-kmods /opt/
# RUN rm -rf /var/yum/cache/*
EOF
fi

#add tests docker images

#build flexran docker image
cd $tmp_path
docker build --squash -t $dockerimagename .
#delete tmp path flexran_build
cd $local_path
# rm -rf $tmp_path

