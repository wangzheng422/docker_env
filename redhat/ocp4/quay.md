# quay.redhat.ren

https://github.com/zhangchl007/quay

https://github.com/quay/quay/blob/master/docs/development-container.md

```bash
git clone https://github.com/zhangchl007/quay

ENCRYPTED_ROBOT_TOKEN_MIGRATION_PHASE=new-installation

bash self-cert-generate.sh redhat.ren quay.redhat.ren
sudo sh pre-quaydeploy.sh

docker-compose  -f docker-compose.config.yml  up -d

firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --reload
firewall-cmd --list-all

# username/password: quayconfig / redhat


```