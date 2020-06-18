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
        sendfile on;
        sendfile_max_chunk 512k;
      server {
          listen       80;
          server_name  _;
            root /www/data/;
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
./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -d 6000 -f split.list.2m.aa

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -d 6000 -f split.list.10m.aa

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -d 6000 -f split.list.100m.aa

# worker-0
./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -d 6000 -f split.list.2m.ab

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -d 6000 -f split.list.10m.ab

./cassowary run -u http://39.134.201.77/ -c 10 -t 30 -d 6000 -f split.list.100m.ab

# infra0
./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -d 6000 -f split.list.2m.ac

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -d 6000 -f split.list.10m.ac

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -d 6000 -f split.list.100m.ac

# infra1
./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -d 6000 -f split.list.2m.ad

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -d 6000 -f split.list.10m.ad

./cassowary run -u http://39.134.201.78/ -c 10 -t 30 -d 6000 -f split.list.100m.ad


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
        path: /data_ext/mnt/
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


# on worker3
cat list.2m | sed "s/\/data_ext\/mnt//" > list.2m.web
cat list.10m | sed "s/\/data_ext\/mnt//" > list.10m.web
cat list.100m | sed "s/\/data_ext\/mnt//" > list.100m.web

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
./cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f split.list.2m.aa

./cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f split.list.10m.aa

./cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f split.list.100m.aa

# worker-0
./cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f split.list.2m.ab

./cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f split.list.10m.ab

./cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f split.list.100m.ab

# infra0
./cassowary run -u http://39.134.204.76/ -c 10 -t 30 -d 6000 -f split.list.2m.ac

./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -d 6000 -f split.list.10m.ac

./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -d 6000 -f split.list.100m.ac

# infra1
./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -d 6000 -f split.list.2m.ad

./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -d 6000 -f split.list.10m.ad

./cassowary run -u http://39.134.204.77/ -c 10 -t 30 -d 6000 -f split.list.100m.ad

ps -ef | grep cassowary | grep run | awk '{print $2}' | xargs -I DEMO kill DEMO

```