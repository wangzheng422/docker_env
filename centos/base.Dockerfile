FROM centos:7

RUN yum -y update && yum -y install centos-release-gluster epel-release which iproute bind-utils wget htop bash-completion curl net-tools java-1.8.0-openjdk && yum -y update