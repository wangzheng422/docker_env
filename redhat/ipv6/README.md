# ipv6

vps上面给的ipv6地址是/64的， 但是docker配置里面，要用/80的，小一点的。

```bash
docker run -itd nicolaka/netshoot

docker exec -it d ip a

sysctl net.ipv6.conf.ens3.accept_ra=2

sysctl net.ipv6.conf.ens3.proxy_ndp=1

ip -6 neigh add proxy 2001:19f0:6001:2e45:2:242:ac11:2 dev ens3

ping6

cat << EOF >  /etc/sysctl.d/docker-ipv6.conf

net.ipv6.conf.all.accept_ra=2
net.ipv6.conf.eth0.accept_ra=2

EOF

```