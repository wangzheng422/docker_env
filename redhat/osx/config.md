# OSX / Win configuration

# osx

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

## nerd font & hypter

```bash
# on osx
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

brew tap-info homebrew/cask-fonts --json | jq -r '.[]|(.formula_names[],.cask_tokens[])'

brew info font-hack-nerd-font

brew install --cask font-hack-nerd-font 

# brew install --cask font-noto-serif-cjk-sc font-noto-sans-cjk-sc font-noto-nerd-font

# Fira Code Nerd Font
brew install --cask font-fira-code-nerd-font

brew install --cask font-sauce-code-pro-nerd-font

brew install --cask hyper

# if brew remove faild with mac version error
# https://stackoverflow.com/questions/55353778/brew-cask-update-or-uninstall-error-definition-is-invalid-invalid-depends-on
# /usr/bin/find "$(brew --prefix)/Caskroom/"*'/.metadata' -type f -name '*.rb' -print0 | /usr/bin/xargs -0 /usr/bin/perl -i -0pe 's/depends_on macos: \[.*?\]//gsm;s/depends_on macos: .*//g'

# set proxy for npm
# npm config edit
npm config set proxy http://127.0.0.1:5085
npm config set https-proxy http://127.0.0.1:5085


# hyper
# https://medium.com/cloud-native-the-gathering/hyper-terminal-plugins-that-will-make-your-life-easier-859897df79d6
# https://github.com/bnb/awesome-hyper
```
```json
module.exports = {
  config: {
    // default font size for all tabs
    fontSize: 16,
    fontFamily: '"Hack Nerd Font", Menlo, "DejaVu Sans Mono", Consolas, "Lucida Console", monospace',
    // ... other config options
 
    // add the hypercwd configuration object like this
    hypercwd: {
    //   initialWorkingDirectory: '~/Documents'
        initialWorkingDirectory: '~/'
    }
  },
  plugins: [
    'hypercwd',
    'nord-hyper',
    'hyperterm-dibdabs',
    'hyper-search',
    'hyper-reorderable-tabs',
    'hyper-quit',
    'hyper-savetext',
  ],
}

```
## starship & related
```bash
# iterm default font "monaco"

brew install starship

cp .zshrc .zshrc.bak

# edit .zshrc, add followin 
ZSH_THEME=""
eval "$(starship init zsh)"

cat << 'EOF' > ~/.zshrc

EOF

# Fira Code Nerd Font
# up/down 110, left/right 100

# https://starship.rs/presets/#pure
# https://gist.github.com/ryo-ARAKI/48a11585299f9032fa4bda60c9bba593
cat << 'EOF' > ~/.config/starship.toml

[character]
error_symbol = "[✖](bold red) "

[cmd_duration]
min_time = 10_000  # Show command duration over 10,000 milliseconds (=10 sec)
format = " took [$duration]($style)"

[directory]
truncation_length = 5
format = "[$path]($style)[$lock_symbol]($lock_style) "

[git_branch]
format = " [$symbol$branch]($style) "
symbol = "🍣 "
style = "bold yellow"

[git_commit]
commit_hash_length = 8
style = "bold white"

[git_state]
format = '[\($state( $progress_current of $progress_total)\)]($style) '

[git_status]
conflicted = "⚔️ "
ahead = "🏎️ 💨 ×${count}"
behind = "🐢 ×${count}"
diverged = "🔱 🏎️ 💨 ×${ahead_count} 🐢 ×${behind_count}"
untracked = "🛤️  ×${count}"
stashed = "📦 "
modified = "📝 ×${count}"
staged = "🗃️  ×${count}"
renamed = "📛 ×${count}"
deleted = "🗑️  ×${count}"
style = "bright-white"
format = "$all_status$ahead_behind"

[hostname]
ssh_only = false
format = "<[$hostname]($style)>"
# trim_at = "-"
style = "bold dimmed white"
disabled = false

[julia]
format = "[$symbol$version]($style) "
symbol = "ஃ "
style = "bold green"

[memory_usage]
format = "$symbol[${ram}( | ${swap})]($style) "
threshold = 70
style = "bold dimmed white"
disabled = false

[package]
disabled = true

[python]
format = "[$symbol$version]($style) "
style = "bold green"

[rust]
format = "[$symbol$version]($style) "
style = "bold green"

[time]
time_format = "%T"
format = "🕙 $time($style) "
style = "bright-white"
disabled = false

[username]
style_user = "bold dimmed blue"
show_always = false

EOF

# https://superuser.com/questions/700406/zsh-not-recognizing-ls-colors
export CLICOLOR=1
alias ls="ls --color=auto"

# on my zsh
omz update

brew install zsh zsh-completions

# https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git fetch --prune origin
git reset --hard origin/master
git clean -f -d

cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git fetch --prune origin
git reset --hard origin/master
git clean -f -d


```

## window manage

https://github.com/rxhanson/Rectangle

```bash
brew install --cask rectangle

```

## clear clipboard

```bash
pbcopy < /dev/null

```
## git-lfs

因为基础镜像包含了intel fpga的基础开发包，所以我们要把一个很大的文件，加入到git项目里面，这里，我们就要用到[Git Large File Storage (LFS)](https://git-lfs.github.com/)

```bash
# on osx
brew install git-lfs
# Update your git config to finish installation:

#   # Update global git config
#   $ git lfs install

#   # Update system git config
#   $ git lfs install --system

/Users/wzh/Desktop/dev/container.build.demo
git lfs install
# Updated git hooks.
# Git LFS initialized.

git lfs track "*.bz2.*"

# split intel sdk into 1GB chunks
split -b 1000m nr5g_19.10.03.bz2 nr5g_19.10.03.bz2.
```

## monitorcontroller

https://github.com/MonitorControl/MonitorControl

## geoip database

https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb

## keepassxc

- https://keepassxc.org/
- https://source.redhat.com/temporary_mojo/temp_personal_wiki/using_the_keepassxc_browser_extension_to_fill_in_the_usernamepintotp

# git proxy

```bash
# https://gist.github.com/laispace/666dd7b27e9116faece6#gistcomment-2836692
git config --global http.https://github.com.proxy socks5://127.0.0.1:1086

git config --global http.proxy 'socks5://127.0.0.1:5085'
git config --global https.proxy 'socks5://127.0.0.1:5085'

git config --global --unset http.proxy
git config --global --unset https.proxy

# for ssh
# osx
Host github.com
    User git
    ProxyCommand nc -v -x 127.0.0.1:1086 %h %p
# win10
Host github.com
    User git
    ProxyCommand connect -S 127.0.0.1:1086 %h %p
```

# bing wallpaper

I used to use the following github site to download the wallpaper: https://github.com/thejandroman/bing-wallpaper

Now I use the following site: http://bimg.top/down-help

```bash
# on vultr
export VAR_DIR=/root/tmp/bing/
mkdir -p $VAR_DIR/img
cd $VAR_DIR

wget https://github.com/ameizi/bing-wallpaper
grep 'download 4k' bing-wallpaper | sed 's/^.*href="//' | sed 's/" rel=.*$//' > list

cd $VAR_DIR/img
while IFS= read -r url;do
    fileName=`echo $url | sed 's/^.*id=OHR\.//'`
    test -f "$fileName" ||  wget -O "$fileName" "$url" || rm -f "$fileName"
    echo $fileName
done < $VAR_DIR/list



```

# color

## nord

https://www.nordtheme.com/ports

## theme

https://dev.to/loctran016/setting-hyper-with-wsl-2-44f2

```bash


```

https://coteditor.com/

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

network 
- https://stackoverflow.com/questions/64112003/how-to-access-service-running-in-wsl2-from-windows-host-using-127-0-0-1
- https://stackoverflow.com/questions/65625762/wsl2-use-localhost-to-access-windows-service
- https://medium.com/@mdavis332/hyper-v-nat-w-linux-vm-1d245be6ded1
- https://stackoverflow.com/questions/65716797/cant-ping-ubuntu-vm-from-wsl2-ubuntu
- https://www.cnblogs.com/sewain/p/15042389.html

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

全屏或者窗口→剪切板或者截屏文件夹 都用一系列 '功能键+prtsc' 组合 就可以实现


## system monitor

https://github.com/zhongyang219/TrafficMonitor

https://openhardwaremonitor.org/

https://www.wisecleaner.com.cn/wise-system-monitor.html

https://www.hwinfo.com/download/

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

wox
everything

## sec network

- https://www.tinc-vpn.org/
- https://omniedge.io/download/windows

- https://landrop.app/#downloads

## font & theme

- [nerd fonts](https://www.nerdfonts.com/)
- [starship](https://starship.rs/)
- [mactype import mac font into windows](https://github.com/snowie2000/mactype)
- https://zhuanlan.zhihu.com/p/354603010
- https://zhuanlan.zhihu.com/p/308481493
- [oh my posh](https://ohmyposh.dev/)

## 动画

- https://www.fable.app/

## phone camera share

- https://obs.ninja/

## desktop customize & widgets

- https://win10widgets.com/
- https://docs.rainmeter.net/manual/plugins/speedfan/
- https://github.com/files-community/Files
- https://github.com/ahmetb/RectangleWin
- [DevToys](https://github.com/veler/DevToys)

## winget

- [winget proxy](https://github.com/microsoft/winget-cli/issues/190)
- [enalbe cache in vpn](https://docs.microsoft.com/en-us/windows/deployment/update/waas-delivery-optimization-reference#enable-peer-caching-while-the-device-connects-via-vpn)

winget support system proxy, just set the proxy in system configuration

```ps1
winget search filezilla
```

## monitor brightness

[Twinkle Tray: Brightness Slider](https://www.microsoft.com/zh-cn/p/twinkle-tray-brightness-slider/9pljwwsv01lk#activetab=pivot:overviewtab)

## make bootable usb

- [Create a bootable Windows 10 installation USB on macOS](https://jensd.be/1349/windows/create-a-bootable-windows-10-installation-usb-on-macos)
- [How to Make a Windows 10 USB Using Your Mac - Build a Bootable ISO From Your Mac's Terminal](https://www.freecodecamp.org/news/how-make-a-windows-10-usb-using-your-mac-build-a-bootable-iso-from-your-macs-terminal/)

```bash
# format the usb using ms-fat

# mount win11 iso

cd /Volumes/USB/

rsync -vha --exclude=sources/install.wim /Volumes/CCCOMA_X64FRE_ZH-CN_DV9/* ./

brew install wimlib

wimlib-imagex split /Volumes/CCCOMA_X64FRE_ZH-CN_DV9/sources/install.wim ./sources/install.swm 3800

```

## install win10

- [微软谜之操作，竟然官方帮助用户跳过Win11的CPU/TPM安装限制](https://min.news/zh-cn/tech/283264316ab734c33aca41065b8ea649.html)
  - [Ways to install Windows 11](https://support.microsoft.com/en-us/windows/ways-to-install-windows-11-e0edbbfb-cfc5-4011-868b-2ce77ac7c70e)
  - [How to Create a Windows 10 Bootable USB on Mac](https://www.switchingtomac.com/tutorials/how-to-create-a-windows-10-bootable-usb-on-mac/)
  - [Support splitting of install.wim via "wimlib-imagex split" to avoid hitting 4GB file size limit of fat32](https://github.com/jsamr/bootiso/issues/32#issuecomment-756010571)
- [Creating a Windows 10 Install USB when FAT32 has 4GB max file size](https://apple.stackexchange.com/questions/348561/creating-a-windows-10-install-usb-when-fat32-has-4gb-max-file-size)

经过实践，发现只能手动在finder里面进行操作，不能直接在terminal里面进行操作，以下命令在terminal里面支持以后，U盘就不能启动了，原因不知道。

[最后发现](https://apple.stackexchange.com/questions/348561/creating-a-windows-10-install-usb-when-fat32-has-4gb-max-file-size)，只能用微软官方的[MediaCreationTool1809.exe](https://go.microsoft.com/fwlink/?LinkId=691209)才可以，他运行在win10上，现下载现制作。

```bash
diskutil eraseDisk MS-DOS 'USB' MBR /dev/disk3

cd /Volumes/USB/

rsync -vha --exclude=sources/install.wim /Volumes/CCCOMA_X64FRE_ZH-CN_DV9/* /Volumes/USB/

cd ~/Downloads/tmp/win
wimlib-imagex split /Volumes/CCCOMA_X64FRE_ZH-CN_DV9/sources/install.wim ./install.swm 4000

rsync -vha ./*.swm /Volumes/USB/sources/

```

## conemu

https://conemu.github.io/

# win 10 real steps

1. login using @outlook.com
   1. enable hello pin
2. install from store
   1. install wsl2 
   2. install powershell 
<!-- 3. https://github.com/microsoft/PowerToys -->

# scoop

https://scoop-docs.vercel.app/docs/misc/Using-Scoop-behind-a-proxy.html#do-you-need-this

```shell
[net.webrequest]::defaultwebproxy = new-object net.webproxy "http://192.168.253.1:5085"

iex (new-object net.webclient).downloadstring('https://get.scoop.sh')

scoop config proxy 192.168.253.1:5085
scoop bucket known

scoop install git
git config --global credential.helper manager-core

scoop bucket add extras
scoop bucket add nerd-fonts

# scoop install powertoys googlechrome tightvnc notepadplusplus vscode wox everything python
# scoop install powertoys googlechrome tightvnc notepadplusplus vscode

scoop install noto-nf firacode-nf sourcecodepro-nf

reg import "C:\Users\wzh\scoop\apps\notepadplusplus\current\install-context.reg"
reg import "C:\Users\wzh\scoop\apps\vscode\current\install-context.reg"
reg import "C:\Users\wzh\scoop\apps\vscode\current\install-associations.reg"
# reg import  "C:\Users\wzh\scoop\apps\python\current\install-pep-514.reg"

# scoop bucket add nonportable
# scoop install mactype-np

scoop install https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/oh-my-posh.json
cp .\powerlevel10k_rainbow.omp.json ~/

# https://devblogs.microsoft.com/powershell/announcing-psreadline-2-1-with-predictive-intellisense/
# Install-Module PSReadLine 
# Set-PSReadLineOption -PredictionSource History

mkdir C:\Users\wzh\Documents\PowerShell\
New-Item $PROFILE

notepad++ $PROFILE
# content
oh-my-posh --init --shell pwsh --config ~/powerlevel10k_rainbow.omp.json | Invoke-Expression
Set-PSReadLineOption -PredictionSource History

# https://superuser.com/questions/1486054/windows-terminal-predefined-tabs-on-startup
"startupActions": "new-tab -p \"PowerShell\" -d C:\\Users\\wzh ; new-tab -p \"PowerShell\" -d C:\\Users\\wzh ; new-tab -p \"PowerShell\" -d C:\\Users\\wzh ; new-tab -p \"PowerShell\" -d C:\\Users\\wzh ; new-tab -p \"PowerShell\" -d C:\\Users\\wzh ; new-tab -p \"PowerShell\" -d C:\\Users\\wzh ; ",

$file = "~/.ssh/config"
$file = Resolve-Path -Path "~/.ssh/config"
New-Item $file -ItemType File
notepad++ $file
# content
StrictHostKeyChecking no
UserKnownHostsFile=\\.\NUL

scoop install starship vcredist2019
scoop uninstall vcredist2019

notepad++ $PROFILE
# content
Invoke-Expression (&starship init powershell)
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -Function ForwardChar
Set-PSReadLineOption -Colors @{ InlinePrediction = '#9E9E9E'}

$file = "~/.config/starship.toml"
$file = Resolve-Path -Path "~/.config/starship.toml"
New-Item $file -ItemType File
notepad++ $file

# https://github.com/thismat/nord-windows-terminal

scoop install filezilla ntop

scoop bucket add nirsoft
scoop install whatinstartup nircmd

# enable linux subsystem and vm platform
# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
# https://segmentfault.com/a/1190000016677670
# https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl_howto/
# on vultr
podman run --name rocky-container rockylinux/rockylinux:8.5
podman export rocky-container -o rocky-container.tar

wsl --import Rocky C:\Users\wzh\self\wsl\rocky\ .\rocky-container.tar
wsl -l -v
wsl -d Rocky
wsl --shutdown

sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.sjtug.sjtu.edu.cn/rocky|g' \
    -i.bak \
    /etc/yum.repos.d/Rocky-*.repo
yum -y update
yum install glibc-langpack-en passwd sudo cracklib-dicts -y
yum reinstall passwd sudo cracklib-dicts -y
# newUsername=wzh
adduser -G wheel wzh
passwd wzh
cat << 'EOF' >> /etc/wsl.conf
# Automatically mount Windows drive when the distribution is launched
[automount]

# Set to true will automount fixed drives (C:/ or D:/) with DrvFs under the root directory set above. Set to false means drives won't be mounted automatically, but need to be mounted manually or with fstab.
enabled = true

# Sets the directory where fixed drives will be automatically mounted. This example changes the mount location, so your C-drive would be /c, rather than the default /mnt/c. 
root = /

# DrvFs-specific options can be specified.  
options = "metadata,uid=1000,gid=1000,umask=077,fmask=11,case=off"

# Sets the `/etc/fstab` file to be processed when a WSL distribution is launched.
mountFsTab = true

# Network host settings that enable the DNS server used by WSL 2. This example changes the hostname, sets generateHosts to false, preventing WSL from the default behavior of auto-generating /etc/hosts, and sets generateResolvConf to false, preventing WSL from auto-generating /etc/resolv.conf, so that you can create your own (ie. nameserver 1.1.1.1).
[network]
hostname = RockyWSL
generateHosts = true
generateResolvConf = true

# Set whether WSL supports interop process like launching Windows apps and adding path variables. Setting these to false will block the launch of Windows processes and block adding $PATH environment variables.
[interop]
enabled = false
appendWindowsPath = false

# Set the user when launching a distribution with WSL.
[user]
default = root
# default = wzh

# [boot]
# systemd=true
EOF

wsl --shutdown
wsl -l -v
wsl -d Rocky

dnf install -y epel-release
dnf group list
dnf install coreutils --allowerasing -y
dnf group install 'Server with GUI' 'Development Tools' -y


winget search --moniker chrome
winget install Google.Chrome
winget search --moniker powertoys
winget install Microsoft.PowerToys
# winget install rainmeter

```