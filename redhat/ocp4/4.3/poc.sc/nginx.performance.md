# nginx performance

## test on worker1
```bash
skopeo copy docker://docker.io/nginx:latest docker://registry.redhat.ren:5443/docker.io/nginx:latest

cat << 'EOF' > nginx-conf.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redhat-nginx-conf
data:
  nginx.conf: |
    user root;
    worker_processes  auto;
    error_log  /var/log/nginx/error.log;

    events {
        use epoll;
        multi_accept on;
        worker_connections  10240;
    }

    http {

      server {
          listen       80;
          server_name  _;
            root /www/data/;
            allow   39.134.204.0/24;
            allow   117.177.241.0/24;
            allow   39.137.101.0/24;
            allow   39.134.201.0/24;
            deny    all;

          location / {

          }
      }

    }
EOF
oc apply -n zxcdn -f nginx-conf.yaml


cat << 'EOF' > nginx-conf.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redhat-nginx-conf
data:
  nginx.conf: |
    user root;
    worker_processes  auto;
    error_log  /var/log/nginx/error.log;
    worker_rlimit_nofile 100000;
 
    events {
        use epoll;
        multi_accept on;
      worker_connections  10240;
    }

    http {
        sendfile on;

      server {
          listen       80;
          server_name  _;
            root /www/data/;
            allow   39.134.204.0/24;
            allow   117.177.241.0/24;
            allow   39.137.101.0/24;
            allow   39.134.201.0/24;
            deny    all;

          location / {
            #include       /etc/nginx/mime.types;
            default_type  application/octet-stream;
            access_log off;
            keepalive_timeout  65;
            keepalive_requests 200;
            reset_timedout_connection on;
            sendfile on;
            tcp_nopush on;
            gzip on;
            gzip_min_length 256;
            gzip_comp_level 3;
            gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
            open_file_cache max=10000 inactive=30s;
            open_file_cache_valid    60s;
            open_file_cache_min_uses 2;
            open_file_cache_errors   on;
 
            

          }
      }

    }
EOF
oc apply -n zxcdn -f nginx-conf.yaml

cat << 'EOF'> nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: redhat-001
  namespace: zxcdn
  labels: 
    pod: redhat-001
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "webcache-001-macvlan",
      "default-route": ["39.134.201.94"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-1.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/nginx:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /www/data
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data/mnt/zxdfs
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: redhat-002
  namespace: zxcdn
  labels: 
    pod: redhat-002
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "webcache-002-macvlan",
      "default-route": ["39.134.201.94"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-1.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/nginx:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /www/data
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data/mnt/zxdfs
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}

EOF
oc apply -f nginx.yaml

oc delete -f nginx.yaml

# on worker-2
# curl http://39.134.201.77/webcache-001/media/httpcache/0/00/ffed805ce64883195ff8a4dffcea7000


# sed -i "s/\/data\/mnt\/zxdfs/http:\/\/39.134.201.77/" list.shuf.all

# sed -i "s/\/data\/mnt\/zxdfs//" list.shuf.all

# tool list
# https://gist.github.com/denji/8333630
# https://awesomeopensource.com/project/denji/awesome-http-benchmark

# on worker1
var_basedir="/data/mnt"
find $var_basedir -type f -size -2M  > list.2m
find $var_basedir -type f -size -10M  -size +2M > list.10m
find $var_basedir -type f -size +10M > list.100m
find $var_basedir -type f > list

cat list.2m | sed "s/\/data\/mnt\/zxdfs//" > list.2m.web
cat list.10m | sed "s/\/data\/mnt\/zxdfs//" > list.10m.web
cat list.100m | sed "s/\/data\/mnt\/zxdfs//" > list.100m.web

cat list.2m.web | shuf > list.shuf.2m
cat list.10m.web | shuf > list.shuf.10m
cat list.100m.web | shuf > list.shuf.100m
cat list.10m.web list.100m.web | shuf > list.shuf.+2m

rm -f split.list.*

var_total=4
split -n l/$var_total list.shuf.2m split.list.2m.
split -n l/$var_total list.shuf.10m split.list.10m.
split -n l/$var_total list.shuf.100m split.list.100m.
split -n l/$var_total list.shuf.+2m split.list.+2m.

scp split.list.*.aa 39.134.201.66:~/
scp split.list.*.ab 39.137.101.28:~/
scp split.list.*.ac 117.177.241.23:~/
scp split.list.*.ad 117.177.241.24:~/

# worker-2
./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -n 9999999 -f split.list.2m.aa

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -n 9999999 -f split.list.10m.aa

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -n 9999999 -f split.list.100m.aa

# worker-0
./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -n 9999999 -f split.list.2m.ab

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -n 9999999 -f split.list.10m.ab

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -n 9999999 -f split.list.100m.ab

# infra0
./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -n 9999999 -f split.list.2m.ac

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -n 9999999 -f split.list.10m.ac

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -n 9999999 -f split.list.100m.ac

# infra1
./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -n 9999999 -f split.list.2m.ad

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -n 9999999 -f split.list.10m.ad

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -n 9999999 -f split.list.100m.ad


ps -ef | grep cassowary | grep run | awk '{print $2}' | xargs -I DEMO kill DEMO


oc rsync redhat-001:/var/log/nginx/ ./

cat access.log | sed 's/^.*GET//' | sed 's/HTTP.*//' | wc -l
cat access.log | sed 's/^.*GET//' | sed 's/HTTP.*//' | sort | uniq -d | wc -l
```

## test on worker-3


```bash

oc apply -f zte-macvlan.yaml


cat << 'EOF'> nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: redhat-001
  namespace: zxcdn
  labels: 
    pod: redhat-001
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-001-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/nginx:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /www/data
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data_ext04/mnt/
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: redhat-002
  namespace: zxcdn
  labels: 
    pod: redhat-002
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-002-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/nginx:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /www/data
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data_ext04/mnt/
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}

---
kind: Pod
apiVersion: v1
metadata:
  name: demo
  namespace: zxcdn
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-003-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: demo1
      image: >- 
        registry.redhat.ren:5443/docker.io/wangzheng422/centos:centos7-test
      env:
        - name: key
          value: value
      command: ["iperf3", "-s", "-p" ]
      args: [ "6666" ]
      imagePullPolicy: Always


EOF
oc apply -f nginx.yaml

oc delete -f nginx.yaml


# on worker3
# var_basedir="/data_ext04"
var_truebase="data_ext04"
var_basedir="/$var_truebase/mnt"

mkdir -p /$var_truebase/list.tmp
cd /$var_truebase/list.tmp
find $var_basedir -type f -size -2M  > list.2m
find $var_basedir -type f -size -10M  -size +2M > list.10m
find $var_basedir -type f -size +10M > list.100m
find $var_basedir -type f > list

cat list.2m | sed "s/\/$var_truebase\/mnt//" > list.2m.web
cat list.10m | sed "s/\/$var_truebase\/mnt//" > list.10m.web
cat list.100m | sed "s/\/$var_truebase\/mnt//" > list.100m.web

cat list.2m.web | shuf > list.shuf.2m
cat list.10m.web | shuf > list.shuf.10m
cat list.100m.web | shuf > list.shuf.100m
cat list.10m.web list.100m.web | shuf > list.shuf.+2m

rm -f split.list.*

var_total=3
split -n l/$var_total list.shuf.2m split.list.2m.
split -n l/$var_total list.shuf.10m split.list.10m.
split -n l/$var_total list.shuf.100m split.list.100m.
split -n l/$var_total list.shuf.+2m split.list.+2m.

scp split.list.*.aa 39.134.201.66:~/
scp split.list.*.ab 39.137.101.28:~/
scp split.list.*.ac 117.177.241.23:~/
scp split.list.*.ad 117.177.241.24:~/

# worker-2
./cassowary run -u http://39.134.204.76/ -c 20 -t 30 -n 1 -f split.list.2m.aa

./cassowary run -u http://39.134.204.76/ -c 30 -t 30 -n 1 -f split.list.10m.aa

./cassowary run -u http://39.134.204.76/ -c 30 -t 30 -n 1 -f split.list.100m.aa

# worker-0
./cassowary run -u http://39.134.204.77/ -c 30 -t 30 -n 1  -f split.list.2m.ab

./cassowary run -u http://39.134.204.77/ -c 20 -t 30 -n 1  -f split.list.10m.ab

./cassowary run -u http://39.134.204.77/ -c 30 -t 30 -n 1  -f split.list.100m.ab

./cassowary run -u http://39.134.204.77/ -c 30 -t 30 -n 1  -f split.list.+2m.ab

# infra0
./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -n 1 -f split.list.2m.ac

./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -n 1 -f split.list.10m.ac

./cassowary run -u http://39.134.204.77/ -c 20 -t 30 -n 1 -f split.list.100m.ac

# infra1
./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -n 1 -f split.list.2m.ad

./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -n 1 -f split.list.10m.ad

./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -n 1 -f split.list.100m.ad

ps -ef | grep cassowary | grep run | awk '{print $2}' | xargs -I DEMO kill DEMO


# debug 
scp root@39.134.204.73:/data_ext/list.tmp/split.list.*.aa ./

oc rsync ./ demo:/root/

oc exec demo -it -- cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f /root/split.list.100m.aa



```


## worker-0

```bash



cat << 'EOF'> nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: redhat-001
  namespace: zxcdn
  labels: 
    pod: redhat-001
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "webcache-011-macvlan",
      "default-route": ["39.137.101.126"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/nginx:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /www/data
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data/mnt/
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: redhat-002
  namespace: zxcdn
  labels: 
    pod: redhat-002
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "webcache-012-macvlan",
      "default-route": ["39.137.101.126"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/nginx:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /www/data
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data/mnt/
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}

---
kind: Pod
apiVersion: v1
metadata:
  name: demo
  namespace: zxcdn
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-003-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: demo1
      image: >- 
        registry.redhat.ren:5443/docker.io/wangzheng422/centos:centos7-test
      env:
        - name: key
          value: value
      command: ["iperf3", "-s", "-p" ]
      args: [ "6666" ]
      imagePullPolicy: Always


EOF
oc apply -f nginx.yaml

oc delete -f nginx.yaml




var_truebase="data"
var_basedir="/$var_truebase/mnt"

mkdir -p /$var_truebase/list.tmp
cd /$var_truebase/list.tmp

cat list.16k | sed "s/\/data\/mnt//" > list.16k.web
cat list.128k | sed "s/\/data\/mnt//" > list.128k.web
cat list.2m | sed "s/\/data\/mnt//" > list.2m.web

cat list.16k.web | shuf > list.shuf.16k
cat list.128k.web | shuf > list.shuf.128k
cat list.2m.web | shuf > list.shuf.2m
cat list.128k.web list.2m.web | shuf > list.shuf.+16k

rm -f split.list.*

var_total=3
split -n l/$var_total list.shuf.16k split.list.16k.
split -n l/$var_total list.shuf.128k split.list.128k.
split -n l/$var_total list.shuf.2m split.list.2m.
split -n l/$var_total list.shuf.+16k split.list.+16k.

scp split.list.*.aa 39.134.201.66:~/
scp split.list.*.ab 39.137.101.28:~/
scp split.list.*.ac 117.177.241.23:~/
scp split.list.*.ad 117.177.241.24:~/

```


## debug

```bash

cat << 'EOF'> apache.yaml
apiVersion: v1
kind: Pod
metadata:
  name: redhat-001
  namespace: zxcdn
  labels: 
    pod: redhat-001
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-001-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/httpd:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /usr/local/apache2/htdocs/
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data_ext/mnt/
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: redhat-002
  namespace: zxcdn
  labels: 
    pod: redhat-002
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-002-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: webcache-001-main
      image: registry.redhat.ren:5443/docker.io/httpd:latest
      imagePullPolicy: Always
  
      volumeMounts:
        - name: webcache-volumes
          mountPath: /usr/local/apache2/htdocs/
        - mountPath: /etc/nginx # mount nginx-conf volumn to /etc/nginx
          readOnly: true
          name: nginx-conf
        - mountPath: /var/log/nginx
          name: log

      resources:
        requests:
          cpu: 8.0
          memory: 48Gi
        limits:
          cpu: 8.0
          memory: 48Gi
      securityContext:
        privileged: true
        runAsUser: 0

  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data_ext/mnt/
    - name: nginx-conf
      configMap:
        name: redhat-nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
        items:
          - key: nginx.conf
            path: nginx.conf
    - name: log
      emptyDir: {}

---
kind: Pod
apiVersion: v1
metadata:
  name: demo
  namespace: zxcdn
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-003-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: demo1
      image: >- 
        registry.redhat.ren:5443/docker.io/wangzheng422/centos:centos7-test
      env:
        - name: key
          value: value
      command: ["iperf3", "-s", "-p" ]
      args: [ "6666" ]
      imagePullPolicy: Always


EOF
oc apply -f apache.yaml

oc delete -f apache.yaml

cat << EOF > demo.yaml
---
kind: Pod
apiVersion: v1
metadata:
  name: demo-pod
  annotations:
    k8s.v1.cni.cncf.io/networks: '
    [{
      "name": "redhat-001-macvlan",
      "default-route": ["39.134.204.65"] 
    }]'
spec:
  nodeSelector:
    kubernetes.io/hostname: 'worker-3.ocpsc.redhat.ren'
  restartPolicy: Always
  containers:
    - name: demo1
      image: >- 
        registry.redhat.ren:5443/docker.io/wangzheng422/centos:centos7-test
      env:
        - name: key
          value: value
      command: ["iperf3", "-s", "-p" ]
      args: [ "6666" ]
      imagePullPolicy: Always
      securityContext:
        privileged: true
        runAsUser: 0
      volumeMounts:
        - name: webcache-volumes
          mountPath: /data_ext/
  serviceAccount: zxcdn-app
  volumes:
    - name: webcache-volumes
      hostPath:
        path: /data_ext/
EOF
oc apply -n zxcdn -f demo.yaml

oc delete -n zxcdn -f demo.yaml


semanage permissive -a httpd_t

semanage permissive -d httpd_t


```