#!/bin/bash
local_path=$PWD
tmp_path=flexran_build
dockerimagename=flexran.docker.registry/flexran_vdu
http_proxy=`env|grep http_proxy |awk -F '=' '{print $2}'`
https_proxy=`env|grep https_proxy|awk -F '=' '{print $2}'`
rm -rf $tmp_path
rm -rf bin/nr5g/gnb/l1/l1app
echo "Note please first build dpdk!!!"
source ./set_env_var.sh
./flexran_build.sh $*
if [ ! -f "bin/nr5g/gnb/l1/l1app" ]; then
   echo "flexran build failed , docker image not build!!"
   exit -1
else
   echo "flexran build success"
fi
echo "build xran"
cd framework/enhanced_bbupool/build/
make clean
make all
cd $local_path
cd xran
./build.sh xclean
./build.sh SAMPLEAPP

cd $local_path
mkdir $tmp_path
mkdir $tmp_path/flexran
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
#rm -rf $tmp_path/flexran/xran

#touch dockerfile
#cd $local_path
if [ -z $http_proxy ];then
    cat > flexran_build/Dockerfile << EOF
FROM centos:7.9.2009
RUN yum update -y && yum install -y libhugetlbfs-utils libhugetlbfs-devel libhugetlbfs numactl-devel pciutils libaio libaio-devel net-tools libpcap
WORKDIR /root/
COPY flexran ./flexran
EOF
else
    cat > $tmp_path/Dockerfile << EOF
FROM centos:7.9.2009
ENV http_proxy $http_proxy
ENV https_proxy $https_proxy
RUN yum update -y && yum install -y libhugetlbfs-utils libhugetlbfs-devel libhugetlbfs numactl-devel pciutils libaio libaio-devel net-tools libpcap
WORKDIR /root/
COPY flexran ./flexran
EOF
fi

#add tests docker images

#build flexran docker image
cd $tmp_path
docker build -t $dockerimagename .
#delete tmp path flexran_build
cd $local_path
rm -rf $tmp_path

