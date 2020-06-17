# nginx performance

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
    worker_processes  30;
    error_log  /var/log/nginx/error.log;
    events {
      worker_connections  10240;
    }
    http {

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
EOF
oc apply -f nginx.yaml

# on worker-2
# curl http://39.134.201.77/webcache-001/media/httpcache/0/00/ffed805ce64883195ff8a4dffcea7000

sed -i "s/\/data\/mnt\/zxdfs/http:\/\/39.134.201.77/" list.shuf.all

# tool list
# https://gist.github.com/denji/8333630

# https://github.com/btfak/sniper
cat list.shuf.all | shuf > url.test
./sniper -c 30 -t 600 -f url.test

```