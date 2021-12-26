# OSX / Win configuration

```bash
cat << EOF > ~/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

EOF

# in .zshrc
# alias ssh="ssh -F ~/.ssh/config"

# vm extend disk , 硬盘扩容
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

conda config --set proxy_servers.http http://127.0.0.1:5085
conda config --set proxy_servers.https http://127.0.0.1:5085

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

# Kap
# https://stackoverflow.com/questions/52591553/how-to-use-ffmpeg-with-gpu-support-on-macos
ffmpeg -h encoder=h264_videotoolbox
ffmpeg -h encoder=hevc_videotoolbox
# https://github.com/wulkano/Kap/blob/master/contributing.md
# cat << EOF > .npmrc
# sass_binary_site=https://npm.taobao.org/mirrors/node-sass/
# registry=https://registry.npm.taobao.org
# EOF
cd /Users/wzh/Desktop/dev/Kap
yarn config set proxy http://127.0.0.1:5085
yarn config set https-proxy http://127.0.0.1:5085

yarn
yarn run pack

ffmpeg -i test.mp4 -c:v h264_videotoolbox -profile:v high -level 4.2 -crf 18 test1.mp4

ffmpeg -i test.mp4 -c:v hevc_videotoolbox -profile:v main10  -crf 18 test1.mp4


###############################
## ESHOW driver clean
# https://apple.stackexchange.com/questions/351529/identifying-and-removing-unknown-sound-device
sudo -i
cd /Library/Audio/Plug-Ins/HAL
rm -rf ESHOW.driver
rm -rf DongleAudio.driver
rm -rf EshowAudio.driver
# then reboot

bindkey -l
# .safe
# command
# emacs
# isearch
# listscroll
# main
# menuselect
# vicmd
# viins
# viopp
# visual

bindkey -M main
```

# bing wallpaper

I used to use the following github site to download the wallpaper: https://github.com/thejandroman/bing-wallpaper

Now I use the following site: http://bimg.top/down-help

```bash
# on vultr
mkdir -p /data/bing/img
cd /data/bing

wget https://github.com/ameizi/bing-wallpaper
grep 'download 4k' bing-wallpaper | sed 's/^.*href="//' | sed 's/" rel=.*$//' > list

cd /data/bing/img
while IFS= read -r url;do
    fileName=`echo $url | sed 's/^.*id=OHR\.//'`
    test -f "$fileName" ||  wget -O "$fileName" "$url" || rm -f "$fileName"
    echo $fileName
done < /data/bing/list

```

# color

## nord

https://www.nordtheme.com/ports

## theme

https://dev.to/loctran016/setting-hyper-with-wsl-2-44f2

```bash


```

# win10

## wsl2 rocky

install:
- https://docs.rockylinux.org/guides/interoperability/rocky_to_wsl_howto/

release:
- https://loesspie.com/2021/01/27/wsl2-compact-disk-win10/

hyper:
- https://dev.to/loctran016/setting-hyper-with-wsl-2-44f2
- https://gist.github.com/leodutra/a6cebe11db5414cdaedc6e75ad194a00
- https://github.com/Powerlevel9k/powerlevel9k/wiki/Stylizing-Your-Prompt



## auto start
https://www.how2shout.com/linux/how-to-start-wsl-services-automatically-on-ubuntu-with-windows-10-startup/

## share folder

https://devblogs.microsoft.com/commandline/access-linux-filesystems-in-windows-and-wsl-2/

## screen brush

https://epic-pen.com/

https://github.com/antfu/live-draw

https://github.com/geovens/gInk

## remap caps

https://github.com/microsoft/PowerToys

## access host ip

https://stackoverflow.com/questions/65625762/wsl2-use-localhost-to-access-windows-service

https://devdojo.com/mvnarendrareddy/access-windows-localhost-from-wsl2

## screen shot

https://github.com/flameshot-org/flameshot#windows

windows buildin ( pic, movie )

print键 截全屏并复制到剪贴板(dos时代就有的功能)

alt+print键 截窗口并复制到剪贴板

win+print键 截全屏并保存到我的图片(win10新功能)

win+g 录屏(win10新功能)

win+v 打开剪贴板

区域→剪切板：`win+shift+s`

全屏或者窗口→剪切板或者截屏文件夹 都用一系列 “功能键+prtsc” 组合 就可以实现


## system monitor

https://github.com/zhongyang219/TrafficMonitor

https://openhardwaremonitor.org/

https://www.wisecleaner.com.cn/wise-system-monitor.html

## backup

https://www.ubackup.com/free-backup-software.html

## pkg

scoop:
- https://zhuanlan.zhihu.com/p/128955118
- https://scoop-docs.vercel.app/docs/misc/Using-Scoop-behind-a-proxy.html#do-you-need-this

## sftp

https://cyberduck.io/

filezilla

## media player

https://www.stellarplayer.com/?chan=zj_11

## launcher

wow + everything





