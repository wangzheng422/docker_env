FROM centos

RUN yum -y update && yum -y install deltarpm centos-release-gluster epel-release which iproute bind-utils wget && yum -y update