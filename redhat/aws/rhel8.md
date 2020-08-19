# rhel8 prepare

```bash
# https://access.redhat.com/solutions/3755871
dnf install /usr/bin/reposync

reposync -q -n --repo rhel-8-for-x86_64-appstream-rpms -p /repositories --downloadcomps --download-metadata




```