#!/bin/bash
set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="ovn_debug_$TIMESTAMP"
LOG_FILE="$OUTPUT_DIR/combined_debug_data.txt"
NODES=("worker-01-demo" "worker-02-demo") 
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

# 1. Get an OVN Pod
echo "Finding an OVN pod..."
OVN_POD=$(oc get pods -n "$NAMESPACE" -l "$OVN_LABEL" -o jsonpath='{.items[0].metadata.name}')
echo "Using OVN Pod: $OVN_POD"

# 2. Collect OVN Northbound
echo "Collecting OVN Northbound Data..."
run_nb() {
    local cmd="$1"
    local desc="$2"
    local full_cmd="oc exec -n $NAMESPACE $OVN_POD -c ovn-controller -- $cmd"
    
    log_section "Cluster (via $OVN_POD)" "$desc" "$cmd"
    eval "$full_cmd" >> "$LOG_FILE" 2>&1 || echo "Error running command" >> "$LOG_FILE"
}

run_nb "ovn-nbctl show" "OVN NB Show"
run_nb "ovn-nbctl list ACL" "OVN NB ACL List"
run_nb "ovn-nbctl list Logical_Router_Policy" "OVN NB Logical Router Policies"
run_nb "ovn-nbctl list Logical_Switch_Port" "OVN NB Switch Ports"
run_nb "ovn-nbctl list Logical_Router_Port" "OVN NB Router Ports"
run_nb "ovn-nbctl list Load_Balancer" "OVN NB Load Balancers"

# 2.1 Collect OVN Southbound
echo "Collecting OVN Southbound Data..."
run_sb() {
    local cmd="$1"
    local desc="$2"
    local full_cmd="oc exec -n $NAMESPACE $OVN_POD -c ovn-controller -- $cmd"
    
    log_section "Cluster (via $OVN_POD)" "$desc" "$cmd"
    eval "$full_cmd" >> "$LOG_FILE" 2>&1 || echo "Error running command" >> "$LOG_FILE"
}

run_sb "ovn-sbctl show" "OVN SB Show"
run_sb "ovn-sbctl lflow-list" "OVN SB Logical Flows"

# 3. Collect OVS Data
for NODE_KEY in "${NODES[@]}"; do
    echo "Processing Node matching: $NODE_KEY"
    FULL_NODE_NAME=$(oc get nodes -o name | grep "$NODE_KEY" | head -n 1 | cut -d/ -f2)
    
    if [ -z "$FULL_NODE_NAME" ]; then
        echo "WARNING: Could not find node matching '$NODE_KEY'. Skipping."
        continue
    fi
    
    NODE_POD=$(oc get pods -n "$NAMESPACE" -l "$OVN_LABEL" --field-selector spec.nodeName="$FULL_NODE_NAME" -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$NODE_POD" ]; then
        echo "WARNING: No ovnkube-node pod found on $FULL_NODE_NAME. Skipping."
        continue
    fi
    
    run_ovs() {
        local cmd="$1"
        local desc="$2"
        # Fix: use ovn-controller container as it has ovs-vsctl and ip commands available
        local full_cmd="oc exec -n $NAMESPACE $NODE_POD -c ovn-controller -- $cmd"
        
        log_section "$FULL_NODE_NAME (via $NODE_POD)" "$desc" "$cmd"
        eval "$full_cmd" >> "$LOG_FILE" 2>&1 || echo "Error running command" >> "$LOG_FILE"
    }

    echo "  - Collecting OVS/Network data for $FULL_NODE_NAME..."
    run_ovs "ovs-vsctl show" "OVS VSCTL Show"
    # run_ovs "ovs-ofctl -O OpenFlow13 dump-flows br-int" "OVS OpenFlow Dumps" # Skipped
    run_ovs "ip a" "IP Addresses"
    run_ovs "ip route" "IP Routes"
done

echo "Done. All data in $LOG_FILE"
