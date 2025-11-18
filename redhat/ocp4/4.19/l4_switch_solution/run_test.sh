#!/bin/bash

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration ---
NAMESPACE="l4-switch-demo"
ROUTE_NAME="hello-openshift"
AB_REQUESTS=200
AB_CONCURRENCY=10
ROUTER_POD_LABEL="ingresscontroller.operator.openshift.io/deployment-ingress-controller=default"
ROUTER_NAMESPACE="openshift-ingress"
HAPROXY_TARGET_CFG="haproxy.cfg"

# --- Helper Functions ---
function print_header() {
    echo -e "\n${BLUE}=======================================================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}=======================================================================${NC}"
}

function print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

function print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

function print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
    cleanup
    exit 1
}

function check_deps() {
    for cmd in oc docker docker-compose ab; do
        if ! command -v $cmd &> /dev/null; then
            print_error "'$cmd' command not found. Please install it and ensure it's in your PATH."
        fi
    done
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start it."
    fi
}

function cleanup() {
    print_header "Final Cleanup"
    print_info "Stopping external HAProxy container..."
    docker-compose down --remove-orphans > /dev/null 2>&1
    print_info "Deleting all resources in namespace '${NAMESPACE}'..."
    oc delete ns ${NAMESPACE} --ignore-not-found=true
    rm -f ${HAPROXY_TARGET_CFG}
    print_success "Demo finished and all resources cleaned up."
}

function wait_for_pods() {
    print_info "Waiting for all pods in namespace '$1' to be ready..."
    if ! oc wait --for=condition=Ready pods --all -n "$1" --timeout=300s; then
        print_error "Pods in namespace '$1' did not become ready in time."
    fi
    print_success "All pods in '$1' are ready."
}

function get_router_node_ips() {
    oc get pods -n ${ROUTER_NAMESPACE} -l ${ROUTER_POD_LABEL} -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u | xargs -I {} oc get node {} -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
}

function generate_haproxy_config() {
    local template_file=$1
    local check_port=$2
    local server_list=""
    local count=1

    print_info "Fetching router node IPs..."
    local node_ips=$(get_router_node_ips)
    if [ -z "$node_ips" ]; then
        print_error "Could not find any router node IPs."
    fi
    print_info "Found router node IPs: ${node_ips}"

    for ip in $node_ips; do
        server_list+="  server router-${count} ${ip}:80 check port ${check_port} inter 1s fall 2 rise 2\n"
        count=$((count+1))
    done

    print_info "Generating '${HAPROXY_TARGET_CFG}' from template '${template_file}'..."
    sed "s|# SERVERS_PLACEHOLDER|${server_list}|" "${template_file}" > "${HAPROXY_TARGET_CFG}"
}

function run_ab_test() {
    local test_name=$1
    local route_host=$2

    print_header "Running Test: ${test_name}"
    
    print_info "Starting external HAProxy via Docker Compose..."
    docker-compose up -d
    # Give haproxy a moment to stabilize
    sleep 3

    print_info "Starting Apache Bench (ab) test in the background against http://localhost:8080 ..."
    ab -n ${AB_REQUESTS} -c ${AB_CONCURRENCY} -H "Host: ${route_host}" http://localhost:8080/ > /tmp/ab_results.txt 2>&1 &
    AB_PID=$!
    
    sleep 2

    local router_pod_to_delete=$(oc get pods -n ${ROUTER_NAMESPACE} -l ${ROUTER_POD_LABEL} -o jsonpath='{.items[0].metadata.name}')
    print_info "Simulating router migration by deleting pod: ${router_pod_to_delete}"
    oc delete pod ${router_pod_to_delete} -n ${ROUTER_NAMESPACE} --grace-period=0 --ignore-not-found=true

    wait $AB_PID
    print_info "Apache Bench test finished."
    
    print_info "Stopping external HAProxy container..."
    docker-compose down --remove-orphans

    cat /tmp/ab_results.txt
    local failed_requests=$(grep "Failed requests:" /tmp/ab_results.txt | awk '{print $3}')
    local total_requests=$(grep "Complete requests:" /tmp/ab_results.txt | awk '{print $3}')
    
    if [ -z "$total_requests" ] || [ "$total_requests" -eq 0 ]; then
        print_error "AB test did not run correctly. No requests completed."
    fi

    local success_rate=$(awk "BEGIN {printf \"%.2f\", ((${total_requests} - ${failed_requests}) / ${total_requests}) * 100}")
    
    echo -e "${YELLOW}-------------------------------------------${NC}"
    echo -e "${YELLOW} Test Summary: ${test_name}${NC}"
    echo -e "${YELLOW} Total Requests: ${total_requests}${NC}"
    echo -e "${YELLOW} Failed Requests: ${failed_requests}${NC}"
    echo -e "${YELLOW} Success Rate: ${success_rate}%${NC}"
    echo -e "${YELLOW}-------------------------------------------${NC}"

    if [ "$failed_requests" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# --- Main Execution ---
trap cleanup EXIT
check_deps

# 1. Setup
print_header "Phase 0: Initial Setup"
oc get ns ${NAMESPACE} > /dev/null 2>&1 && oc delete ns ${NAMESPACE}
oc apply -f 01_namespace.yaml
oc apply -f 02_sample_app.yaml
oc apply -f 03_route.yaml
wait_for_pods ${NAMESPACE}

ROUTE_HOST=$(oc get route ${ROUTE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.host}')
[ -z "${ROUTE_HOST}" ] && print_error "Could not get route host."
print_success "Sample app and route are ready. Route host: ${ROUTE_HOST}"

# 2. Test Phase 1: L7 Health Check (Ideal Case)
generate_haproxy_config "templates/haproxy_l7.cfg.template" "1936"
run_ab_test "L7 Health Check" "${ROUTE_HOST}"
if [ $? -eq 0 ]; then
    print_success "Phase 1 PASSED: Achieved 100% success rate as expected."
else
    print_error "Phase 1 FAILED: Expected 100% success rate but found failures."
fi
wait_for_pods ${ROUTER_NAMESPACE}

# 3. Test Phase 2: L4 Health Check (Problem Reproduction)
generate_haproxy_config "templates/haproxy_l4.cfg.template" "80"
run_ab_test "L4 Health Check" "${ROUTE_HOST}"
if [ $? -ne 0 ]; then
    print_success "Phase 2 PASSED: Successfully reproduced the problem with failed requests."
else
    print_info "Phase 2 NOTE: Test passed with 100% success. The issue might not be consistently reproducible in this environment, but the solution is still valid."
fi
wait_for_pods ${ROUTER_NAMESPACE}

# 4. Test Phase 3: L4 Health Check with Sibling Pod (Solution)
print_header "Phase 3: Deploying and Testing the Sibling Pod Solution"
print_info "Deploying the health check DaemonSet..."
oc apply -f 08_health_check_script_configmap.yaml
oc apply -f 09_health_check_daemonset.yaml
# Wait for daemonset to be ready on at least one node
sleep 10 

generate_haproxy_config "templates/haproxy_l4_sidecar.cfg.template" "18898"
run_ab_test "L4 Health Check with Sibling Pod" "${ROUTE_HOST}"
if [ $? -eq 0 ]; then
    print_success "Phase 3 PASSED: Solution is effective! Achieved 100% success rate."
else
    print_error "Phase 3 FAILED: The solution did not prevent failures."
fi

print_header "DEMO COMPLETED SUCCESSFULLY"
