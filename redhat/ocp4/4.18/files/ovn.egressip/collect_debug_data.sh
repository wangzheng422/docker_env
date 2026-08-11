#!/bin/bash
set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="ovn_debug_$TIMESTAMP"
LOG_FILE="$OUTPUT_DIR/combined_debug_data.txt"
NODES=("master-01-demo" "master-02-demo" "master-03-demo" "worker-01-demo" "worker-02-demo") 
NAMESPACE="openshift-ovn-kubernetes"
OVN_LABEL="app=ovnkube-node"

mkdir -p "$OUTPUT_DIR"
echo "Collecting debug info to: $LOG_FILE"
touch "$LOG_FILE"

# Helper function for logging
log_section() {
    local node="$1"
    local desc="$2"
    local cmd="$3"

    {
        echo ""
        echo "################################################################################"
        echo "Node: $node"
        echo "Description: $desc"
        echo "Command: $cmd"
        echo "Timestamp: $(date)"
        echo "################################################################################"
        echo ""
    } >> "$LOG_FILE"
}

# Helper to run commands inside the pod
run_in_pod() {
    local pod="$1"
    local node_name="$2"
    local cmd="$3"
    local desc="$4"
    
    local full_cmd="oc exec -n $NAMESPACE $pod -c ovn-controller -- $cmd"
    
    log_section "$node_name (via $pod)" "$desc" "$cmd"
    # Use eval to handle complex command strings with pipes/quotes if necessary, though direct execution is safer. 
    # Here we stick to the original pattern for consistency.
    eval "$full_cmd" >> "$LOG_FILE" 2>&1 || echo "Error running command: $cmd" >> "$LOG_FILE"
}

# Main Loop: Process each node
for NODE_KEY in "${NODES[@]}"; do
    echo "================================================================================"
    echo "Processing Node matching: $NODE_KEY"
    
    # Identify full node name
    FULL_NODE_NAME=$(oc get nodes -o name | grep "$NODE_KEY" | head -n 1 | cut -d/ -f2)
    
    if [ -z "$FULL_NODE_NAME" ]; then
        echo "WARNING: Could not find node matching '$NODE_KEY'. Skipping."
        continue
    fi
    
    # Identify OVN Pod on this node
    NODE_POD=$(oc get pods -n "$NAMESPACE" -l "$OVN_LABEL" --field-selector spec.nodeName="$FULL_NODE_NAME" -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$NODE_POD" ]; then
        echo "WARNING: No ovnkube-node pod found on $FULL_NODE_NAME. Skipping."
        continue
    fi

    echo "  Target Pod: $NODE_POD"

    # 1. Collect OVN Northbound Data (from this node's perspective)
    echo "  - Collecting OVN Northbound Data..."
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl show" "OVN NB Show"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl list ACL" "OVN NB ACL List"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl list Logical_Router_Policy" "OVN NB Logical Router Policies"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl list Logical_Switch_Port" "OVN NB Switch Ports"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl --columns=name,port_security list Logical_Switch_Port" "OVN NB Port Security"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl list Logical_Router_Port" "OVN NB Router Ports"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl list Load_Balancer" "OVN NB Load Balancers"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl list NAT" "OVN NB NAT Rules"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-nbctl list Address_Set" "OVN NB Address Sets"

    # 2. Collect OVN Southbound Data (from this node's perspective)
    echo "  - Collecting OVN Southbound Data..."
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-sbctl show" "OVN SB Show"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-sbctl --columns=logical_port,port_security list Port_Binding" "OVN SB Port Security"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-sbctl list Chassis" "OVN SB Chassis"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovn-sbctl lflow-list" "OVN SB Logical Flows"

    # 3. Collect OVS/Network Data
    echo "  - Collecting OVS & Network Data..."
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovs-vsctl show" "OVS VSCTL Show"
    # run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ovs-ofctl -O OpenFlow13 dump-flows br-int" "OVS OpenFlow Dumps" # Skipped as per request/comment
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ip a" "IP Addresses"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ip rule" "IP Rules"
    run_in_pod "$NODE_POD" "$FULL_NODE_NAME" "ip route show table all" "IP Routes (All Tables)"

done

echo "Done. All data in $LOG_FILE"
