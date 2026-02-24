import argparse
import logging
import subprocess
import sys
import time

from kubernetes import client, config, watch
from kubernetes.client.rest import ApiException

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('ocp-egress-gw')

def run_cmd(cmd: str, ignore_errors=False) -> str:
    logger.debug(f"Running command: {cmd}")
    try:
        result = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        if not ignore_errors:
            logger.error(f"Command failed: {cmd}\nError: {e.stderr.strip()}")
            raise e
        return ""

def manage_route(action: str, pod_cidr: str, node_ip: str, dev: str = "eth0"):
    """
    Adds or deletes a route. 
    Uses 'replace' instead of 'add' to avoid 'File exists' errors on existing routes.
    """
    if action == "add":
        try:
            run_cmd(f"ip route replace {pod_cidr} via {node_ip} dev {dev}")
            logger.info(f"Route configured: {pod_cidr} via {node_ip} dev {dev}")
        except Exception:
            pass
    elif action == "delete":
        try:
            run_cmd(f"ip route del {pod_cidr} via {node_ip} dev {dev}")
            logger.info(f"Route deleted: {pod_cidr} via {node_ip} dev {dev}")
        except Exception:
            pass

def watch_nodes(dev: str = "eth0"):
    """
    Watch OpenShift/Kubernetes Nodes for changes and update routing tables automatically.
    """
    try:
        # Load kubeconfig from default location (~/.kube/config)
        config.load_kube_config()
    except Exception as e:
        logger.error(f"Failed to load kubeconfig. Make sure you have KUBECONFIG set or ~/.kube/config exists. Error: {e}")
        sys.exit(1)

    v1 = client.CoreV1Api()
    w = watch.Watch()
    
    logger.info(f"Starting OpenShift Node watcher for dynamic routing on device {dev}...")
    
    # Process existing nodes first
    try:
        nodes = v1.list_node()
        for node in nodes.items:
            process_node_event("ADDED", node, dev)
    except ApiException as e:
        logger.error(f"Exception when calling CoreV1Api->list_node: {e}")

    try:
        for event in w.stream(v1.list_node):
            process_node_event(event['type'], event['object'], dev)
    except Exception as e:
        logger.error(f"Watch stream error: {e}")

def process_node_event(event_type: str, node, dev: str):
    node_name = node.metadata.name
    pod_cidr = node.spec.pod_cidr
    
    node_ip = None
    if node.status.addresses:
        for addr in node.status.addresses:
            if addr.type == "InternalIP":
                node_ip = addr.address
                break
                
    if not pod_cidr or not node_ip:
        logger.debug(f"Node {node_name} missing pod_cidr or InternalIP. pod_cidr={pod_cidr}, IP={node_ip}")
        return

    if event_type in ["ADDED", "MODIFIED"]:
        manage_route("add", pod_cidr, node_ip, dev)
    elif event_type == "DELETED":
        manage_route("delete", pod_cidr, node_ip, dev)

def add_tenant(args):
    """
    Adds a macvlan interface and iptables rules for a new tenant.
    """
    logger.info(f"Adding tenant: {args.name}")
    try:
        # 1. Create macvlan link
        run_cmd(f"ip link add link {args.dev} name macvlan-{args.name} type macvlan mode bridge")
        
        # 2. Add IP address
        run_cmd(f"ip addr add {args.gw_ip}/24 dev macvlan-{args.name}")
        
        # 3. Bring up interface
        run_cmd(f"ip link set macvlan-{args.name} up")
        
        # 4. Add Mangle Rule for packet marking (identifying source next-hop)
        run_cmd(f"iptables -t mangle -I PREROUTING -i macvlan-{args.name} -j MARK --set-mark {args.mark}")
        
        # 5. Add NAT Rule for SNAT (outgoing on out_dev)
        run_cmd(f"iptables -t nat -I POSTROUTING -o {args.out_dev} -m mark --mark {args.mark} -j SNAT --to-source {args.egress_ip}")
        
        logger.info(f"Successfully configured tenant {args.name} with Gateway IP {args.gw_ip} mapping to Egress IP {args.egress_ip} out via {args.out_dev}")
    except Exception as e:
        logger.error("Failed to add tenant. It might already exist or require root privileges.")

def remove_tenant(args):
    """
    Removes a tenant's macvlan and rules.
    """
    logger.info(f"Removing tenant: {args.name}")
    try:
        # Remove rules first
        run_cmd(f"iptables -t mangle -D PREROUTING -i macvlan-{args.name} -j MARK --set-mark {args.mark}", ignore_errors=True)
        # Note: In production you might want to dynamically find the exact rule or flush by mark, but this is simple enough.
        # SNAT rule deletion requires the exact parameters used during creation:
        egress_ip = args.egress_ip
        out_dev = getattr(args, 'out_dev', 'eth1') # Default to eth1 if not specified for removal
        if egress_ip:
            run_cmd(f"iptables -t nat -D POSTROUTING -o {out_dev} -m mark --mark {args.mark} -j SNAT --to-source {egress_ip}", ignore_errors=True)
            
        # Remove link
        run_cmd(f"ip link set macvlan-{args.name} down", ignore_errors=True)
        run_cmd(f"ip link delete macvlan-{args.name}", ignore_errors=True)
        logger.info(f"Successfully removed tenant {args.name}")
    except Exception as e:
        pass

def show_status(args):
    print("\n--- MACVLAN Interfaces ---")
    print(run_cmd("ip -br link show type macvlan", ignore_errors=True))
    
    print("\n--- IP Routing Table (Pod CIDRs) ---")
    print(run_cmd("ip route show | grep via", ignore_errors=True))
    
    print("\n--- Mangle Rules (Packet Marking) ---")
    print(run_cmd("iptables -t mangle -nL PREROUTING | grep MARK", ignore_errors=True))
    
    print("\n--- NAT Rules (SNAT) ---")
    print(run_cmd("iptables -t nat -nL POSTROUTING | grep SNAT", ignore_errors=True))

def main():
    parser = argparse.ArgumentParser(description="OCP Egress IP Gateway Manager")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    subparsers.required = True

    # Watcher command
    parser_daemon = subparsers.add_parser("daemon", help="Run the K8s node watcher daemon to update routes dynamically")
    parser_daemon.add_argument("--dev", default="eth0", help="Internal network device to route pods to (default: eth0)")
    parser_daemon.set_defaults(func=lambda args: watch_nodes(args.dev))

    # Add tenant command
    parser_add = subparsers.add_parser("add-tenant", help="Add a tenant configuration")
    parser_add.add_argument("--name", required=True, help="Tenant name (e.g., ns-blue)")
    parser_add.add_argument("--gw-ip", required=True, help="Gateway IP for this tenant inside OCP network")
    parser_add.add_argument("--egress-ip", required=True, help="Target external Egress IP to SNAT to")
    parser_add.add_argument("--mark", required=True, type=int, help="Unique iptables mark (e.g., 10)")
    parser_add.add_argument("--dev", default="eth0", help="Internal network device (default: eth0)")
    parser_add.add_argument("--out-dev", default="eth1", help="External network device for SNAT (default: eth1)")
    parser_add.set_defaults(func=add_tenant)

    # Remove tenant command
    parser_remove = subparsers.add_parser("remove-tenant", help="Remove a tenant configuration")
    parser_remove.add_argument("--name", required=True, help="Tenant name (e.g., ns-blue)")
    parser_remove.add_argument("--mark", required=True, type=int, help="Unique iptables mark to remove")
    parser_remove.add_argument("--egress-ip", required=True, help="Egress IP that was configured (for exact rule deletion)")
    parser_remove.add_argument("--out-dev", default="eth1", help="External network device that was used (default: eth1)")
    parser_remove.set_defaults(func=remove_tenant)

    # Status command
    parser_status = subparsers.add_parser("status", help="Show current configuration status")
    parser_status.set_defaults(func=show_status)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
