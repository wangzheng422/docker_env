#!/usr/bin/env python3
"""
OVN Egress IP Controller with Integrated OVN Patching

This controller performs two main functions:
1. Synchronizes AdminPolicyBasedExternalRoute with gateway pod IPs
2. Automatically applies OVN patches (ACLs and Port Security) when pods are created/deleted

Features:
- Watches gateway pods and updates APB routes
- Watches business pods and applies OVN configurations
- Cleans up OVN settings when pods are deleted
- Idempotent operations to prevent unnecessary updates
"""

import os
import time
import threading
import subprocess
from kubernetes import client, config, watch

# ============================================================================
# Configuration from Environment Variables
# ============================================================================

# Gateway Configuration
GATEWAY_NAMESPACE = os.getenv("GATEWAY_NAMESPACE", "ns-egress-infra")
GATEWAY_LABEL = os.getenv("GATEWAY_LABEL", "app=ns-blue-gateway")

# Business Pod Configuration
BUSINESS_NAMESPACE = os.getenv("BUSINESS_NAMESPACE", "ns-blue")
BUSINESS_LABEL = os.getenv("BUSINESS_LABEL", "app=business-app")

# APB Configuration
APB_NAME = os.getenv("APB_NAME", "ns-blue-route")
GROUP = "k8s.ovn.org"
VERSION = "v1"
PLURAL = "adminpolicybasedexternalroutes"

# OVN Configuration
OVN_NAMESPACE = os.getenv("OVN_NAMESPACE", "openshift-ovn-kubernetes")
OVN_POD_LABEL = os.getenv("OVN_POD_LABEL", "app=ovnkube-node")
OVN_CONTAINER = os.getenv("OVN_CONTAINER", "ovn-controller")

# OVN ACL Priority (custom priority to avoid conflicts)
OVN_ACL_PRIORITY = int(os.getenv("OVN_ACL_PRIORITY", "31821"))


# ============================================================================
# OVN Command Execution Helper
# ============================================================================

def execute_ovn_command(node_name, command):
    """
    Execute OVN command on the specific ovnkube-node pod running on the given node.
    
    Args:
        node_name: The node where the target pod is running
        command: The OVN command to execute
        
    Returns:
        tuple: (success: bool, output: str)
    """
    try:
        # Find the ovnkube-node pod on the specific node
        cmd = [
            "oc", "get", "pods",
            "-n", OVN_NAMESPACE,
            "--field-selector", f"spec.nodeName={node_name}",
            "-l", OVN_POD_LABEL,
            "-o", "jsonpath={.items[0].metadata.name}"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        ovn_pod = result.stdout.strip()
        
        if not ovn_pod:
            print(f"  [ERROR] No OVN pod found on node {node_name}")
            return False, ""
        
        print(f"  [Exec] Node: {node_name} (Pod: {ovn_pod})")
        
        # Execute the command in the ovn-controller container
        exec_cmd = [
            "oc", "exec",
            "-n", OVN_NAMESPACE,
            ovn_pod,
            "-c", OVN_CONTAINER,
            "--",
            "bash", "-c", command
        ]
        result = subprocess.run(exec_cmd, capture_output=True, text=True, check=True)
        return True, result.stdout
        
    except subprocess.CalledProcessError as e:
        print(f"  [ERROR] Command failed: {e}")
        print(f"  [ERROR] stderr: {e.stderr}")
        return False, e.stderr
    except Exception as e:
        print(f"  [ERROR] Unexpected error: {e}")
        return False, str(e)


# ============================================================================
# OVN Pod Configuration Functions
# ============================================================================

def get_pod_details(namespace, label):
    """
    Get pod details including name, node, and LSP name.
    
    Returns:
        dict: {'pod_name': str, 'node_name': str, 'lsp_name': str} or None
    """
    try:
        v1 = client.CoreV1Api()
        pods = v1.list_namespaced_pod(namespace, label_selector=label)
        
        if not pods.items:
            print(f"  [WARN] No pods found with label {label} in namespace {namespace}")
            return None
        
        pod = pods.items[0]
        if pod.status.phase != "Running":
            print(f"  [WARN] Pod {pod.metadata.name} is not Running (status: {pod.status.phase})")
            return None
        
        pod_name = pod.metadata.name
        node_name = pod.spec.node_name
        lsp_name = f"{namespace}_{pod_name}"
        
        return {
            'pod_name': pod_name,
            'node_name': node_name,
            'lsp_name': lsp_name
        }
    except Exception as e:
        print(f"  [ERROR] Failed to get pod details: {e}")
        return None



def clean_ovn_pod(namespace, label):
    """
    Clean OVN settings for all pods matching the label.
    Intelligently removes only ACLs that reference non-existent pods.
    
    Args:
        namespace: Pod namespace
        label: Pod label selector
    """
    print("=" * 60)
    print(f"Cleaning Pods [{label}] in Namespace [{namespace}]")
    
    try:
        v1 = client.CoreV1Api()
        pods = v1.list_namespaced_pod(namespace, label_selector=label)
        
        if not pods.items:
            print("  [SKIP] No pods found")
            return
        
        # Get all existing pods in the namespace for orphan detection
        all_pods = v1.list_namespaced_pod(namespace)
        existing_lsp_names = set()
        for pod in all_pods.items:
            existing_lsp_names.add(f"{namespace}_{pod.metadata.name}")
        
        print(f"  >> Found {len(pods.items)} pod(s) to clean, {len(existing_lsp_names)} total pods in namespace")
        
        # Process each matching pod
        for pod in pods.items:
            if pod.status.phase != "Running":
                print(f"  [SKIP] Pod {pod.metadata.name} is not Running (status: {pod.status.phase})")
                continue
            
            pod_name = pod.metadata.name
            node_name = pod.spec.node_name
            lsp_name = f"{namespace}_{pod_name}"
            
            print(f"  Target: Pod={pod_name} | Node={node_name} | LSP={lsp_name}")
            
            # Check ACLs on this node
            print(f"    >> Checking ACLs (Priority {OVN_ACL_PRIORITY}) on node {node_name}...")
            cmd_list_acls = f"""
ovn-nbctl --format=csv --no-heading --columns=_uuid,match find ACL priority={OVN_ACL_PRIORITY}
"""
            success, output = execute_ovn_command(node_name, cmd_list_acls)
            
            if not success or not output.strip():
                print(f"    >> No ACLs with priority {OVN_ACL_PRIORITY} found")
                continue
            
            # Parse ACL output and identify orphaned ACLs
            orphaned_acls = []
            for line in output.strip().split('\n'):
                if not line.strip():
                    continue
                parts = line.split(',', 1)
                if len(parts) < 2:
                    continue
                acl_uuid = parts[0].strip()
                acl_match = parts[1].strip()
                
                # Extract LSP name from match clause
                import re
                lsp_pattern = rf'{namespace}_[a-zA-Z0-9-]+'
                match_result = re.search(lsp_pattern, acl_match)
                
                if match_result:
                    referenced_lsp = match_result.group(0)
                    # Check if this LSP still exists
                    if referenced_lsp not in existing_lsp_names:
                        print(f"    >> Found orphaned ACL: {acl_uuid} (references non-existent pod: {referenced_lsp})")
                        orphaned_acls.append(acl_uuid)
            
            # Remove orphaned ACLs
            if orphaned_acls:
                print(f"    >> Removing {len(orphaned_acls)} orphaned ACL(s)...")
                for acl_uuid in orphaned_acls:
                    cmd_remove = f"""
echo "      Removing ACL {acl_uuid}"
ovn-nbctl remove Logical_Switch {node_name} acls {acl_uuid}
"""
                    execute_ovn_command(node_name, cmd_remove)
            else:
                print(f"    >> No orphaned ACLs found")
        
        print("  Clean Done.")
        
    except Exception as e:
        print(f"  [ERROR] Failed to clean pods: {e}")


def patch_ovn_pod(namespace, label, port_security_mode="keep_port_security"):
    """
    Apply OVN patches for all pods matching the label.
    
    Args:
        namespace: Pod namespace
        label: Pod label selector
        port_security_mode: "clear_port_security" or "keep_port_security"
            - Gateway Pod: use "clear_port_security" (needs to forward traffic)
            - Business Pod: use "keep_port_security" (only sends own traffic)
    """
    print("=" * 60)
    print(f"Configuring Pods [{label}] in Namespace [{namespace}]")
    print(f"  Port Security Mode: {port_security_mode}")
    
    try:
        v1 = client.CoreV1Api()
        pods = v1.list_namespaced_pod(namespace, label_selector=label)
        
        if not pods.items:
            print("  [SKIP] No pods found")
            return
        
        print(f"  >> Found {len(pods.items)} pod(s) to configure")
        
        # Process each matching pod
        for pod in pods.items:
            if pod.status.phase != "Running":
                print(f"  [SKIP] Pod {pod.metadata.name} is not Running (status: {pod.status.phase})")
                continue
            
            pod_name = pod.metadata.name
            node_name = pod.spec.node_name
            lsp_name = f"{namespace}_{pod_name}"
            
            print(f"  Target: Pod={pod_name} | Node={node_name} | LSP={lsp_name}")
            
            # Step 1: Clear Port Security (conditional)
            if port_security_mode == "clear_port_security":
                print("    >> Clearing Port Security (Gateway mode - allows forwarding)...")
                cmd_clear = f"ovn-nbctl clear Logical_Switch_Port {lsp_name} port_security"
                execute_ovn_command(node_name, cmd_clear)
            else:
                print("    >> Keeping Port Security (Business Pod mode - enhanced security)")
            
            # Step 2: Add Stateless ACLs for ALL traffic
            # from-lport: Allow ALL Egress (Pod -> Switch)
            print(f"    >> Adding 'from-lport' stateless allow rule (Priority {OVN_ACL_PRIORITY})...")
            cmd_acl_from = f'ovn-nbctl --type=switch acl-add {node_name} from-lport {OVN_ACL_PRIORITY} "inport == \\"{lsp_name}\\"" allow-stateless'
            success, output = execute_ovn_command(node_name, cmd_acl_from)
            if not success and "Same ACL already existed" not in output:
                print(f"    [WARN] Failed to add from-lport ACL: {output}")
            
            # to-lport: Allow ALL Ingress (Switch -> Pod)
            print(f"    >> Adding 'to-lport' stateless allow rule (Priority {OVN_ACL_PRIORITY})...")
            cmd_acl_to = f'ovn-nbctl --type=switch acl-add {node_name} to-lport {OVN_ACL_PRIORITY} "outport == \\"{lsp_name}\\"" allow-stateless'
            success, output = execute_ovn_command(node_name, cmd_acl_to)
            if not success and "Same ACL already existed" not in output:
                print(f"    [WARN] Failed to add to-lport ACL: {output}")
        
        print("  Done.")
        
    except Exception as e:
        print(f"  [ERROR] Failed to patch pods: {e}")



# ============================================================================
# APB Reconciliation Functions
# ============================================================================

def get_current_gateway_ips(v1):
    """
    Get current gateway pod IPs in Running state.
    
    Returns:
        list: Sorted list of IP addresses
    """
    try:
        pods = v1.list_namespaced_pod(GATEWAY_NAMESPACE, label_selector=GATEWAY_LABEL)
        return sorted([p.status.pod_ip for p in pods.items if p.status.phase == "Running" and p.status.pod_ip])
    except Exception as e:
        print(f"Error listing gateway pods: {e}")
        return []


def reconcile_apb():
    """
    Core reconciliation logic: Compare and synchronize APB with gateway pod IPs.
    """
    v1 = client.CoreV1Api()
    api = client.CustomObjectsApi()
    
    # 1. Get current gateway pod IPs (desired state)
    desired_ips = get_current_gateway_ips(v1)
    if not desired_ips:
        print("No running gateway pods found. Skipping APB sync.")
        return
    
    desired_formatted = [{"ip": ip} for ip in desired_ips]
    
    try:
        # 2. Read current APB resource state
        current_apb = api.get_cluster_custom_object(GROUP, VERSION, PLURAL, APB_NAME)
        current_static_hops = current_apb.get("spec", {}).get("nextHops", {}).get("static", [])
        
        # 3. Idempotency check: Compare desired IPs with actual IPs
        current_ips_str = sorted([hop["ip"] for hop in current_static_hops if "ip" in hop])
        
        if current_ips_str == desired_ips:
            # If identical, skip to prevent watch loop
            return
        
        # 4. If different, apply correction
        print(f"Detect deviation! Desired: {desired_ips}, Current in APB: {current_ips_str}. Correcting...")
        body = {"spec": {"nextHops": {"static": desired_formatted}}}
        api.patch_cluster_custom_object(GROUP, VERSION, PLURAL, APB_NAME, body)
        print("APB Successfully enforced.")
        
    except Exception as e:
        print(f"APB reconciliation failed: {e}")


# ============================================================================
# Pod Watch Functions with Auto-Restart
# ============================================================================

def watch_gateway_pods():
    """
    Watch gateway pods and reconcile APB when changes occur.
    Automatically restarts on errors with exponential backoff.
    """
    retry_delay = 5  # Initial retry delay in seconds
    max_retry_delay = 300  # Maximum retry delay (5 minutes)
    
    while True:
        try:
            v1 = client.CoreV1Api()
            w = watch.Watch()
            print(f"Started watching Gateway Pods in {GATEWAY_NAMESPACE}...")
            
            # Reset retry delay on successful connection
            retry_delay = 5
            
            for event in w.stream(v1.list_namespaced_pod, namespace=GATEWAY_NAMESPACE, label_selector=GATEWAY_LABEL, timeout_seconds=0):
                try:
                    event_type = event['type']
                    pod = event['object']
                    pod_name = pod.metadata.name
                    
                    print(f"[Gateway Event] {event_type}: {pod_name}")
                    
                    # Reconcile APB on any gateway pod change
                    reconcile_apb()
                    
                    # Apply OVN patches for gateway pods
                    if event_type == "ADDED" or event_type == "MODIFIED":
                        if pod.status.phase == "Running":
                            print(f"  >> Applying OVN patches to gateway pod {pod_name}...")
                            clean_ovn_pod(GATEWAY_NAMESPACE, GATEWAY_LABEL)
                            patch_ovn_pod(GATEWAY_NAMESPACE, GATEWAY_LABEL, "clear_port_security")
                    elif event_type == "DELETED":
                        print(f"  >> Gateway pod {pod_name} deleted, cleaning up...")
                        # Note: Pod is already deleted, cleanup happens automatically
                except Exception as e:
                    print(f"[Gateway Watcher] Error processing event: {e}")
                    # Continue watching despite event processing errors
                    continue
                    
        except Exception as e:
            print(f"[Gateway Watcher] Watch stream failed: {e}")
            print(f"[Gateway Watcher] Restarting in {retry_delay} seconds...")
            time.sleep(retry_delay)
            # Exponential backoff
            retry_delay = min(retry_delay * 2, max_retry_delay)


def watch_business_pods():
    """
    Watch business pods and apply OVN patches when they are created/deleted.
    Automatically restarts on errors with exponential backoff.
    """
    retry_delay = 5  # Initial retry delay in seconds
    max_retry_delay = 300  # Maximum retry delay (5 minutes)
    
    while True:
        try:
            v1 = client.CoreV1Api()
            w = watch.Watch()
            print(f"Started watching Business Pods in {BUSINESS_NAMESPACE}...")
            
            # Reset retry delay on successful connection
            retry_delay = 5
            
            for event in w.stream(v1.list_namespaced_pod, namespace=BUSINESS_NAMESPACE, label_selector=BUSINESS_LABEL, timeout_seconds=0):
                try:
                    event_type = event['type']
                    pod = event['object']
                    pod_name = pod.metadata.name
                    
                    print(f"[Business Event] {event_type}: {pod_name}")
                    
                    if event_type == "ADDED" or event_type == "MODIFIED":
                        if pod.status.phase == "Running":
                            print(f"  >> Applying OVN patches to business pod {pod_name}...")
                            # Wait a bit for pod to be fully ready
                            time.sleep(2)
                            clean_ovn_pod(BUSINESS_NAMESPACE, BUSINESS_LABEL)
                            patch_ovn_pod(BUSINESS_NAMESPACE, BUSINESS_LABEL, "keep_port_security")
                    elif event_type == "DELETED":
                        print(f"  >> Business pod {pod_name} deleted, cleaning up...")
                        # Note: Pod is already deleted, cleanup happens automatically
                except Exception as e:
                    print(f"[Business Watcher] Error processing event: {e}")
                    # Continue watching despite event processing errors
                    continue
                    
        except Exception as e:
            print(f"[Business Watcher] Watch stream failed: {e}")
            print(f"[Business Watcher] Restarting in {retry_delay} seconds...")
            time.sleep(retry_delay)
            # Exponential backoff
            retry_delay = min(retry_delay * 2, max_retry_delay)


def watch_apb():
    """
    Watch APB resource changes (prevent manual modifications).
    Automatically restarts on errors with exponential backoff.
    """
    retry_delay = 5  # Initial retry delay in seconds
    max_retry_delay = 300  # Maximum retry delay (5 minutes)
    
    while True:
        try:
            api = client.CustomObjectsApi()
            w = watch.Watch()
            print("Started watching APB Resource...")
            
            # Reset retry delay on successful connection
            retry_delay = 5
            
            for event in w.stream(api.list_cluster_custom_object, GROUP, VERSION, PLURAL, timeout_seconds=0):
                try:
                    resource = event.get('object', {})
                    if resource.get('metadata', {}).get('name') == APB_NAME:
                        # Reconcile on any APB change
                        # Internal comparison logic prevents infinite loops
                        reconcile_apb()
                except Exception as e:
                    print(f"[APB Watcher] Error processing event: {e}")
                    # Continue watching despite event processing errors
                    continue
                    
        except Exception as e:
            print(f"[APB Watcher] Watch stream failed: {e}")
            print(f"[APB Watcher] Restarting in {retry_delay} seconds...")
            time.sleep(retry_delay)
            # Exponential backoff
            retry_delay = min(retry_delay * 2, max_retry_delay)


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("OVN Egress IP Controller Starting...")
    print("=" * 60)
    
    # Print configuration
    print("\n[Configuration]")
    print(f"  Gateway Namespace:  {GATEWAY_NAMESPACE}")
    print(f"  Gateway Label:      {GATEWAY_LABEL}")
    print(f"  Business Namespace: {BUSINESS_NAMESPACE}")
    print(f"  Business Label:     {BUSINESS_LABEL}")
    print(f"  APB Name:           {APB_NAME}")
    print(f"  OVN Namespace:      {OVN_NAMESPACE}")
    print(f"  OVN ACL Priority:   {OVN_ACL_PRIORITY}")
    print()
    
    # Load Kubernetes configuration
    try:
        config.load_incluster_config()
        print("Loaded in-cluster configuration")
    except:
        config.load_kube_config()
        print("Loaded kubeconfig configuration")
    
    # Initial reconciliation
    print("\n[Initial Sync] Performing initial APB reconciliation...")
    reconcile_apb()
    
    print("\n[Initial Sync] Applying OVN patches to existing pods...")
    # Patch gateway pods
    clean_ovn_pod(GATEWAY_NAMESPACE, GATEWAY_LABEL)
    patch_ovn_pod(GATEWAY_NAMESPACE, GATEWAY_LABEL, "clear_port_security")
    
    # Patch business pods
    clean_ovn_pod(BUSINESS_NAMESPACE, BUSINESS_LABEL)
    patch_ovn_pod(BUSINESS_NAMESPACE, BUSINESS_LABEL, "keep_port_security")
    
    print("\n" + "=" * 60)
    print("Starting watch threads...")
    print("=" * 60 + "\n")
    
    # Start watch threads
    threads = [
        threading.Thread(target=watch_gateway_pods, name="GatewayWatcher"),
        threading.Thread(target=watch_business_pods, name="BusinessWatcher"),
        threading.Thread(target=watch_apb, name="APBWatcher")
    ]
    
    for t in threads:
        t.daemon = True
        t.start()
    
    # Keep main thread alive
    try:
        for t in threads:
            t.join()
    except KeyboardInterrupt:
        print("\nController shutting down...")
