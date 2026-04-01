# keycloak-guac-webhook

RHBK + AD + Guacamole Demo 的 event-driven 自动配置组件。

## 组件说明

本目录包含两个组件，共同实现「用户登录后自动配置 Guacamole 连接」的功能：

```
keycloak-guac-webhook/
├── pom.xml                                        # Maven 构建（Keycloak 26.4.7）
├── README.md                                      # 本文档
├── src/main/                                      # Keycloak EventListener SPI（Java）
│   ├── java/com/demo/keycloak/
│   │   ├── GuacWebhookEventListenerProvider.java     # 监听 LOGIN 事件 → POST /sync/<username>
│   │   └── GuacWebhookEventListenerProviderFactory.java  # SPI 工厂（Provider ID: guac-webhook）
│   └── resources/META-INF/services/
│       └── org.keycloak.events.EventListenerProviderFactory  # SPI 注册
└── guac-sync/                                     # 同步服务（Python Flask）
    ├── sync.py                                    # 主服务（321行）
    ├── requirements.txt                           # 依赖：flask, ldap3, psycopg2, requests
    └── Dockerfile                                 # 容器镜像构建
```

## 工作流程

```
用户在 Keycloak 登录
  → [Java SPI] guac-webhook EventListenerProvider.onEvent(LOGIN)
  → HTTP POST http://guac-ldap-sync:5000/sync/<username>
  → [Python] guac-ldap-sync 查询 OpenLDAP（找 ad=<username> 的账号）
  → 写入 Guacamole PostgreSQL（连接组 + RDP 连接 + 权限）
  → 用户登录后立即看到自己的连接列表 ✅
```

---

## 组件一：Keycloak EventListener SPI（Java）

### 构建（无需本地安装 Java/Maven）

```bash
mkdir -p ~/.m2
podman run --rm \
  -v $(pwd):/project:Z \
  -v ~/.m2:/root/.m2:Z \
  docker.io/maven:3.9-eclipse-temurin-21 \
  mvn -f /project/pom.xml package -q -DskipTests

ls -lh target/keycloak-guac-webhook.jar
cp target/keycloak-guac-webhook.jar keycloak-guac-webhook.jar
```

### 部署到 Keycloak（Volume 挂载持久化）

```bash
podman stop keycloak && podman rm keycloak

podman run -d \
  --name keycloak \
  --hostname sso.wzhlab.top \
  --network corp-demo \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD='KeycloakAdmin2024!' \
  -e KC_DB=postgres \
  -e KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak \
  -e KC_DB_USERNAME=keycloak \
  -e KC_DB_PASSWORD='KeycloakDB2024!' \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HTTP_ENABLED=true \
  -e KC_PROXY_HEADERS=xforwarded \
  -e KC_WEBHOOK_URL=http://guac-ldap-sync:5000 \
  -v $(pwd)/keycloak-guac-webhook.jar:/opt/keycloak/providers/keycloak-guac-webhook.jar:Z,ro \
  -p 8080:8080 \
  quay.io/keycloak/keycloak:26.4 start-dev

sleep 60
# 配置 corp realm 启用 event listener（一次性）
podman exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master \
  --user admin --password 'KeycloakAdmin2024!'
podman exec keycloak /opt/keycloak/bin/kcadm.sh update realms/corp \
  -r corp -s 'eventsListeners=["jboss-logging","guac-webhook"]'
```

### 配置

| 环境变量 | 说明 | 默认值 |
|----------|------|--------|
| `KC_WEBHOOK_URL` | guac-ldap-sync 的 base URL | `http://guac-ldap-sync:5000` |

---

## 组件二：guac-ldap-sync（Python Flask）

### 构建镜像

```bash
cd guac-sync
podman build -t guac-ldap-sync:latest .
```

### 启动容器

```bash
podman run -d \
  --name guac-ldap-sync \
  --network corp-demo \
  -e LDAP_URL=ldap://openldap:389 \
  -e LDAP_BIND_DN=cn=admin,dc=wzhlab,dc=top \
  -e LDAP_BIND_PW=LdapAdmin2024! \
  -e LDAP_BASE=ou=People,dc=wzhlab,dc=top \
  -e PG_HOST=postgres \
  -e PG_DB=guacamole \
  -e PG_USER=guacamole \
  -e PG_PASS=GuacamoleDB2024! \
  -e RDP_PASSWORD=DemoPass2024! \
  -e GUAC_BACKEND=http://guacamole:8080 \
  -p 5000:5000 \
  guac-ldap-sync:latest
```

### API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/sync/<username>` | GET/POST | 单用户同步（由 Keycloak SPI 调用） |
| `/sync` | GET/POST | 全量同步（所有用户） |
| `/health` | GET | 健康检查 |

### LDAP description 格式

```
# 个人账号：
description: vm=linux-vm-1 ad=kim.minsoo label=Personal Dev

# 共享账号（多用户）：
description: vm=linux-vm-2 ad=kim.minsoo,park.jiyeon,lee.seungho label=Team AI Shared
```

- `vm=<容器名>` → 目标 VM
- `ad=<用户1>,<用户2>` → 授权的 AD 用户（逗号分隔）
- `label=<显示名>` → Guacamole 连接名前缀

---

## 注意事项

- Keycloak JAR 通过 volume 挂载，`podman restart keycloak` 后仍有效
- event listener 配置存在 Keycloak PostgreSQL 中，重启不丢失
- WARN 日志 `KC-SERVICES0047` 为正常现象，可忽略
- Guacamole DB 初始为空，由 SPI 在每次用户登录时动态填充
