import os
import kubernetes
from kubernetes import config, client

def get_pod_ip_and_set_env():
    try:
        config.load_incluster_config()
    except kubernetes.config.ConfigException:
        # 如果不在集群内部运行，则加载本地配置
        config.load_kube_config()

    v1 = client.CoreV1Api()
    pod_name = os.environ.get("RAY_POD_NAME") # Ray 会自动设置 RAY_POD_NAME 环境变量
    pod_namespace = os.environ.get("RAY_POD_NAMESPACE", "default") # Ray 会自动设置 RAY_POD_NAMESPACE 环境变量，如果没有设置则默认 namespace 为 default

    if not pod_name:
        print("RAY_POD_NAME environment variable not set. Cannot get Pod IP.")
        return

    pod = v1.read_namespaced_pod(name=pod_name, namespace=pod_namespace)
    pod_ip = pod.status.pod_ip

    if pod_ip:
        os.environ["POD_IP"] = pod_ip
        print(f"Pod IP is: {pod_ip}")
        print(f"POD_IP environment variable set to: {os.environ.get('POD_IP')}")
    else:
        print("Could not retrieve Pod IP.")


if __name__ == "__main__":
    get_pod_ip_and_set_env()
    print("wzh test")