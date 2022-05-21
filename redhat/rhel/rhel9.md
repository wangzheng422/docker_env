# rhel9 tips

```bash
subscription-manager register --proxy=$PROXY --auto-attach --username ********* --password ********

subscription-manager repos --proxy=$PROXY --list  > list

# https://docs.fedoraproject.org/en-US/epel/#_el9
subscription-manager repos --proxy=$PROXY --enable codeready-builder-for-rhel-9-$(arch)-rpms

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

cat << EOF > ~/.tmux.conf
setw -g mode-keys vi
EOF

```