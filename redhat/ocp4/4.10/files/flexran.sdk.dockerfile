FROM registry.access.redhat.com/ubi8/ubi:8.4

RUN dnf repolist
RUN sed -i 's|enabled=1|enabled=0|g' /etc/yum/pluginconf.d/subscription-manager.conf
RUN sed -i 's|$releasever|8.4|g' /etc/yum.repos.d/redhat.repo
RUN sed -i '/codeready-builder-for-rhel-8-x86_64-rpms/,/\[/ s/enabled = 0/enabled = 1/' /etc/yum.repos.d/redhat.repo
RUN mv -f /etc/yum.repos.d/ubi.repo /etc/yum.repos.d/ubi.repo.bak

COPY flexran /data/flexran