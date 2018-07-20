FROM centos

RUN yum -y update && yum -y install centos-release-gluster epel-release which iproute bind-utils wget htop bash-completion curl net-tools && yum -y update