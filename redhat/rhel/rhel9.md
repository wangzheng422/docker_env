# rhel9 tips

```bash
export PROXY="127.0.0.1:18801"

subscription-manager register --proxy=$PROXY --auto-attach --username ********* --password ********

subscription-manager repos --proxy=$PROXY --list  > list

# https://docs.fedoraproject.org/en-US/epel/#_el9
subscription-manager repos --proxy=$PROXY --enable codeready-builder-for-rhel-9-$(arch)-rpms

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# cat << EOF > ~/.tmux.conf
# setw -g mode-keys vi
# EOF

# https://centos.pkgs.org/8/epel-x86_64/byobu-5.133-1.el8.noarch.rpm.html
dnf install -y https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/b/byobu-5.133-1.el8.noarch.rpm

dnf install -y htop


```