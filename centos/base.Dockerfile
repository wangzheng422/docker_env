FROM centos:7

RUN mkdir -p /app && yum -y update && yum -y install deltarpm centos-release-gluster epel-release which iproute bind-utils wget htop bash-completion curl net-tools java-1.8.0-openjdk git && yum -y update