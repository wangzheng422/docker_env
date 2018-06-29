FROM centos

RUN yum install wget -y

RUN wget -P /etc/yum.repos.d/ http://download.gluster.org/pub/gluster/glusterfs/LATEST/CentOS/glusterfs-epel.repo

RUN yum -y install epel-release || yum -y update