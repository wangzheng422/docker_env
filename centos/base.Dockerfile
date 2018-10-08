FROM centos:7

RUN yum -y update && yum -y install deltarpm centos-release-gluster epel-release which iproute bind-utils wget htop bash-completion curl net-tools java-1.8.0-openjdk git && yum -y update && yum -y clean

# RUN echo "Asia/shanghai" > /etc/timezone;
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo "Asia/shanghai" > /etc/timezone
