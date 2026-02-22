# colab vscode extension

# 方法 1：使用 Hugging Face CLI 命令行登录（推荐，一劳永逸）
这是在本地最推荐的做法。通过命令行登录后，Token 会被加密保存在本地（默认在 ~/.cache/huggingface/token），以后的所有代码和 Notebook 都不需要再写 Token。

1. 在你的终端（Terminal）中运行以下命令：

```bash
huggingface-cli login
```

2. 终端会提示你输入 Token：
text
Token (will not be visible):
在这里粘贴你的 hf_... Token 并回车（注意：粘贴时屏幕上不会显示任何字符，这是正常的安全机制）。 

3. 提示 Add token as git credential? (Y/n)，如果不打算用 git 上传模型，可以选 n。 

4. 看到 Login successful 后，重启你的 Jupyter Notebook 内核（Restart Kernel），再运行代码就不会有那个报错了。

# 方法 2：使用 .env 环境变量文件（适合项目隔离）

如果你想把配置和项目绑定，可以利用 dotenv。

1. 在你 Notebook 同级目录下创建一个名为 .env 的隐藏文件（不要把它提交到 Git！）。
2. 在 .env 文件里写入：

```bash
HF_TOKEN=hf_你的真实Token
```

3. 在你的代码最开头（第一格），加两行代码读取这个文件（需要先 pip install python-dotenv）：

```python
import os
from dotenv import load_dotenv
load_dotenv() # 这会自动读取当前目录下的 .env 文件并注入环境变量
```

# headscale

```bash
# 在 VPS 上执行
headscale preauthkeys create --user 你的用户名 --reusable --expiration 24h

# 在 Colab 端：
sudo tailscale up --reset --login-server=https://你的VPS地址 --authkey=你的KEY --hostname=colab-m4-node --accept-dns=true

# 在 M4 Mac 端：
sudo tailscale down
sudo tailscale up --login-server=https://你的VPS地址 --accept-dns=true


```

```yaml
dns:
  # 1. 必须配置全局的上游 DNS 
  # 当你访问 baidu.com 时，Headscale 会把请求转发给它们
  nameservers:
    - 1.1.1.1
    - 8.8.8.8

  # 2. 核心开关：开启 MagicDNS
  magic_dns: true

  # 3. 设置你的私有基础域名 (Base Domain)
  # 可以随便起，比如 myvpn.local，或者你自己的真实域名
  base_domain: myvpn.local
```




# tailscale

```bash
%%bash
# 1. 安装 Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# 2. 以 Userspace Networking 模式后台启动守护进程 (绕过 TUN 权限限制)
sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 > tailscaled.log 2>&1 &
sleep 3 

# 3. 接入你的 Headscale 网络 (替换成你的地址和刚才生成的 AuthKey)
sudo tailscale up --login-server=https://你的VPS地址 --authkey=YOUR_PRE_AUTH_KEY --hostname=colab-m4-node --accept-routes

# 4. 安装并配置 SSH 服务
apt-get update && apt-get install -y openssh-server
mkdir -p /var/run/sshd

# 设置 root 密码为 colab123 (因为你在私有 Tailscale 网段内，简单的密码也是安全的)
echo 'root:colab123' | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 5. 启动 SSH 服务
/usr/sbin/sshd

# 6. 打印 Colab 在 Tailscale 里的内网 IP
echo "========================================="
echo "Tailscale IP:"
tailscale ip -4
echo "现在你可以在 Mac 终端执行: ssh root@<上面的IP>"
echo "========================================="
```

# DER

on aliyun der

```bash

# 替换成你自己的真实邮箱，用于接收 Let's Encrypt 的证书过期提醒
curl https://get.acme.sh | sh -s email=your_email@example.com

# 加载环境变量（或者断开 SSH 重新连一次）
source ~/.bashrc


# 1. 导入阿里云 API 密钥
export Ali_Key="你的AccessKey_ID"
export Ali_Secret="你的AccessKey_Secret"

# 2. 发起申请（请把 derp.yourdomain.com 换成你的真实域名）
~/.acme.sh/acme.sh --issue --dns dns_ali -d derp.yourdomain.com



# 1. 创建我们要挂载给 Docker 的证书目录
mkdir -p /opt/certs

# 2. 安装证书，并配置 60 天后的自动更新动作
~/.acme.sh/acme.sh --install-cert -d derp.yourdomain.com \
--key-file       /opt/certs/derp.yourdomain.com.key \
--fullchain-file /opt/certs/derp.yourdomain.com.crt \
--reloadcmd     "docker restart derper"


docker run -d \
  --name derper \
  --restart always \
  --network host \
  -v /opt/certs:/app/certs \
  -v /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock \
  fredliang/derper:latest \
  derper \
  -c=/app/derper.conf \
  -hostname=derp.yourdomain.com \
  -a=:8443 \
  -stunport=3478 \
  -certmode=manual \
  -certdir=/app/certs \
  -verify-clients=true


```

# 防止休眠


📖 使用方法 (图文步骤)

1. **打开你的 Colab 笔记本网页**。
2. **调出开发者工具 (DevTools)：**
* **Mac 快捷键:** 按下 `Cmd + Option + I` (或 `F12`)。
* **或者:** 在网页空白处右键 -> 选择“检查 (Inspect)”。


3. **切换到控制台 (Console)：**
在弹出的开发者工具面板中，找到顶部的 **Console (控制台)** 标签页。
4. **粘贴并执行：**
将上面的 JavaScript 代码完整复制，粘贴到控制台最下方的输入框中，然后按下 **回车 (Enter)**。
5. **确认成功：**
你会看到控制台立刻打印出 `✅ 防休眠脚本已启动！`。之后每隔一分钟，都会打印一条 `🤖 [Colab 保活助手] 正在模拟活跃状态...`。


```js
// Colab 防休眠脚本 (2026年适用)
function keepColabAlive() {
    console.log("🤖 [Colab 保活助手] 正在模拟活跃状态...");
    
    // 尝试寻找并点击 Colab 的连接状态按钮
    const connectButton = document.querySelector('colab-connect-button');
    if (connectButton && connectButton.shadowRoot) {
        const actualButton = connectButton.shadowRoot.querySelector('#connect');
        if (actualButton) {
            actualButton.click();
        }
    }
}

// 每 60,000 毫秒（60秒）执行一次
const keepAliveInterval = setInterval(keepColabAlive, 60000);

console.log("✅ 防休眠脚本已启动！只要不关闭此网页，Colab 将保持运行。");
console.log("🛑 如果需要停止，请运行: clearInterval(keepAliveInterval)");
```