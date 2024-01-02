# 制作rhel驱动rpm

```bash
# first install a rhel9

mount -o ro /dev/sr0 /media

cat << EOF > /etc/yum.repos.d/media.repo
[media-baseos]
name=Media - BaseOS
baseurl=file:///media/BaseOS
gpgcheck=0
enabled=1

[media-appstream]
name=Media - AppStream
baseurl=file:///media/AppStream
gpgcheck=0
enabled=1
EOF

dnf groupinstall -y development


make install



```