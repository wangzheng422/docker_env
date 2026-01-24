#!/bin/bash
set -e

# Configuration
OUTPUT_DIR="ovn_debug_$(date +%Y%m%d_%H%M%S)"
NODES=("worker-01-demo" "worker-02-demo") # Default nodes, can be overridden
NAMESPACE="openshift-ovn-kubernetes"
OVN_LABEL="app=ovnkube-node"

mkdir -p "$OUTPUT_DIR"
echo "Collecting debug info to directory: $OUTPUT_DIR"

# 1. Get an OVN Pod to run NBCTL commands (any ovnkube-node pod will do)
echo "Finding an OVN pod..."
OVN_POD=$(oc get pods -n "$NAMESPACE" -l "$OVN_LABEL" -o jsonpath='{.items[0].metadata.name}')
echo "Using OVN Pod: $OVN_POD"

# 2. Collect OVN Northbound Database Info
echo "Collecting OVN Northbound Data..."
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-nbctl show > "$OUTPUT_DIR/ovn_nb_show.txt"
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-nbctl list ACL > "$OUTPUT_DIR/ovn_acls.txt"
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-nbctl list Logical_Router_Policy > "$OUTPUT_DIR/ovn_policies.txt"
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-nbctl list Logical_Switch_Port > "$OUTPUT_DIR/ovn_lsp.txt"
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-nbctl list Logical_Router_Port > "$OUTPUT_DIR/ovn_lrp.txt"
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-nbctl list Load_Balancer > "$OUTPUT_DIR/ovn_lb.txt"

# 2.1 Collect OVN Southbound Database Info
echo "Collecting OVN Southbound Data..."
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-sbctl show > "$OUTPUT_DIR/ovn_sb_show.txt"
oc exec -n "$NAMESPACE" "$OVN_POD" -c ovn-controller -- ovn-sbctl lflow-list > "$OUTPUT_DIR/ovn_sb_lflow.txt"

# 3. Collect OVS Data from specific nodes
# We need to find the ovnkube-node pod running on each target node to execute ovs commands
for NODE_KEY in "${NODES[@]}"; do
    echo "------------------------------------------------"
    echo "Processing Node matching: $NODE_KEY"
    
    # Fuzzy match node name if exact match fails, or just use the first match
    FULL_NODE_NAME=$(oc get nodes -o name | grep "$NODE_KEY" | head -n 1 | cut -d/ -f2)
    
    if [ -z "$FULL_NODE_NAME" ]; then
        echo "WARNING: Could not find node matching '$NODE_KEY'. Skipping."
        continue
    fi
    
    echo "Found Node: $FULL_NODE_NAME"
    
    # Find the pod on this node
    NODE_POD=$(oc get pods -n "$NAMESPACE" -l "$OVN_LABEL" --field-selector spec.nodeName="$FULL_NODE_NAME" -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$NODE_POD" ]; then
        echo "WARNING: No ovnkube-node pod found on $FULL_NODE_NAME. Skipping."
        continue
    fi
    
    echo "Target Pod: $NODE_POD"
    NODE_DIR="$OUTPUT_DIR/$FULL_NODE_NAME"
    mkdir -p "$NODE_DIR"
    
    # Dump OVS Bridge/Port Config
    echo "  - Collecting ovs-vsctl show..."
    oc exec -n "$NAMESPACE" "$NODE_POD" -c ovn-controller -- ovs-vsctl show > "$NODE_DIR/ovs_vsctl_show.txt"
    
    # Dump OpenFlows (huge output usually) - SKIPPED as per request
    # echo "  - Collecting ovs-ofctl dump-flows..."
    # oc exec -n "$NAMESPACE" "$NODE_POD" -c ovn-controller -- ovs-ofctl -O OpenFlow13 dump-flows br-int > "$NODE_DIR/ovs_flows.txt"
    
    # Dump Conntrack (can be very large, filtering for the relevant IPs if known would be better, but dumping all for analysis)
    # Warning: This might be truncated if too large
    # echo "  - Collecting conntrack entries..."
    # oc exec -n "$NAMESPACE" "$NODE_POD" -c ovn-controller -- ovs-appctl dpctl/dump-conntrack > "$NODE_DIR/conntrack.txt"
    
    # Dump Interface list from OS (using chroot /host usually required, but let's try via container if mapped, 
    # usually ovnkube-node is privileged but might not have host network namespace tools directly in path.
    # A safer bet for IP/Route is 'oc debug node' but that requires interactive or carefully scripted input.
    # We will try basic ip addr inside the container - often it shares host net ns)
    echo "  - Collecting IP addresses and Routes..."
    oc exec -n "$NAMESPACE" "$NODE_POD" -c ovn-controller -- ip a > "$NODE_DIR/ip_a.txt"
    oc exec -n "$NAMESPACE" "$NODE_POD" -c ovn-controller -- ip route > "$NODE_DIR/ip_route.txt"
    
done

echo "------------------------------------------------"
echo "Collection complete. Data saved in $OUTPUT_DIR"
echo "Run: 'tar -czf ${OUTPUT_DIR}.tar.gz $OUTPUT_DIR' to archive."
