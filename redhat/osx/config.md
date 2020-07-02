```bash
cat << EOF > ~/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

EOF

# in .zshrc
# alias ssh="ssh -F ~/.ssh/config"

# vm
# https://access.redhat.com/solutions/4009
pvcreate /dev/sdb 
vgextend rhel /dev/sdb

vgdisplay rhel | egrep 'PE Size|Free  PE'
lvextend -l 100%VG /dev/rhel/root
# lvextend -l 100%VG /dev/rhel/root -r
xfs_growfs /dev/rhel/root

# https://access.redhat.com/articles/3776151
systemctl isolate graphical.target
# systemctl isolate multi-user.target
# startx

systemctl get-default
# multi-user.target
systemctl set-default graphical.target

vi /etc/PackageKit/PackageKit.conf 
ProxyHTTP=http://192.168.253.1:5084


nmcli connection modify ens33 ipv4.dns 192.168.253.2
nmcli connection reload
nmcli connection up ens33

conda config --set proxy_servers.http http://127.0.0.1:5084
conda config --set proxy_servers.https http://127.0.0.1:5084

# from ggplot import *
# https://www.codenong.com/42859781/
conda create --name py36 python=3.6
conda search python
conda info -e

# source activate py36 
conda activate py36

conda install -c anaconda jupyter
conda install -c conda-forge ggplot
conda install -c anaconda seaborn
conda install -c anaconda scikit-learn
conda install -c conda-forge scikit-plot


# ssh
eval `ssh-agent`

ssh-add

ssh-add -L 

```