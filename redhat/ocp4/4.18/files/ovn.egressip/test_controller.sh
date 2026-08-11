#!/bin/bash
# Test script for OVN Egress IP Controller
# This script verifies that the controller correctly applies OVN configurations

set -e

echo "=========================================="
echo "OVN Egress IP Controller Test Suite"
echo "=========================================="
echo ""

# Configuration
GATEWAY_NAMESPACE="ns-egress-infra"
GATEWAY_LABEL="app=ns-blue-gateway"
BUSINESS_NAMESPACE="ns-blue"
BUSINESS_LABEL="app=business-app"
OVN_NAMESPACE="openshift-ovn-kubernetes"
OVN_ACL_PRIORITY=31821

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print test results
print_result() {
    local test_name=$1
    local result=$2
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
    else
        echo -e "${YELLOW}⚠ WARN${NC}: $test_name"
    fi
}

# Test 1: Check if controller is running
echo "Test 1: Controller Deployment Status"
if oc get deployment apb-controller -n $GATEWAY_NAMESPACE &>/dev/null; then
    REPLICAS=$(oc get deployment apb-controller -n $GATEWAY_NAMESPACE -o jsonpath='{.status.availableReplicas}')
    if [ "$REPLICAS" = "1" ]; then
        print_result "Controller is running" "PASS"
    else
        print_result "Controller is not ready (replicas: $REPLICAS)" "FAIL"
    fi
else
    print_result "Controller deployment not found" "FAIL"
fi
echo ""

# Test 2: Check if gateway pod exists
echo "Test 2: Gateway Pod Status"
GATEWAY_POD=$(oc get pod -n $GATEWAY_NAMESPACE -l $GATEWAY_LABEL -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$GATEWAY_POD" ]; then
    GATEWAY_STATUS=$(oc get pod -n $GATEWAY_NAMESPACE $GATEWAY_POD -o jsonpath='{.status.phase}')
    if [ "$GATEWAY_STATUS" = "Running" ]; then
        print_result "Gateway pod is running: $GATEWAY_POD" "PASS"
    else
        print_result "Gateway pod status: $GATEWAY_STATUS" "WARN"
    fi
else
    print_result "Gateway pod not found" "FAIL"
fi
echo ""

# Test 3: Check if business pod exists
echo "Test 3: Business Pod Status"
BUSINESS_POD=$(oc get pod -n $BUSINESS_NAMESPACE -l $BUSINESS_LABEL -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$BUSINESS_POD" ]; then
    BUSINESS_STATUS=$(oc get pod -n $BUSINESS_NAMESPACE $BUSINESS_POD -o jsonpath='{.status.phase}')
    if [ "$BUSINESS_STATUS" = "Running" ]; then
        print_result "Business pod is running: $BUSINESS_POD" "PASS"
    else
        print_result "Business pod status: $BUSINESS_STATUS" "WARN"
    fi
else
    print_result "Business pod not found" "FAIL"
fi
echo ""

# Test 4: Check APB resource
echo "Test 4: AdminPolicyBasedExternalRoute Status"
APB_NAME="ns-blue-route"
if oc get adminpolicybasedexternalroute $APB_NAME &>/dev/null; then
    NEXTHOP_IP=$(oc get adminpolicybasedexternalroute $APB_NAME -o jsonpath='{.spec.nextHops.static[0].ip}')
    if [ -n "$NEXTHOP_IP" ]; then
        print_result "APB nextHop IP: $NEXTHOP_IP" "PASS"
        
        # Check if nextHop matches gateway pod IP
        if [ -n "$GATEWAY_POD" ]; then
            GATEWAY_IP=$(oc get pod -n $GATEWAY_NAMESPACE $GATEWAY_POD -o jsonpath='{.status.podIP}')
            if [ "$NEXTHOP_IP" = "$GATEWAY_IP" ]; then
                print_result "APB nextHop matches gateway pod IP" "PASS"
            else
                print_result "APB nextHop ($NEXTHOP_IP) != gateway IP ($GATEWAY_IP)" "FAIL"
            fi
        fi
    else
        print_result "APB nextHop IP not set" "FAIL"
    fi
else
    print_result "APB resource not found" "FAIL"
fi
echo ""

# Test 5: Check OVN ACLs for gateway pod
if [ -n "$GATEWAY_POD" ] && [ "$GATEWAY_STATUS" = "Running" ]; then
    echo "Test 5: Gateway Pod OVN Configuration"
    
    GATEWAY_NODE=$(oc get pod -n $GATEWAY_NAMESPACE $GATEWAY_POD -o jsonpath='{.spec.nodeName}')
    GATEWAY_LSP="${GATEWAY_NAMESPACE}_${GATEWAY_POD}"
    OVN_POD=$(oc get pods -n $OVN_NAMESPACE --field-selector spec.nodeName=$GATEWAY_NODE -l app=ovnkube-node -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$OVN_POD" ]; then
        # Check for ACLs with priority 31821
        ACL_COUNT=$(oc exec -n $OVN_NAMESPACE $OVN_POD -c ovn-controller -- bash -c \
            "ovn-nbctl --format=csv --no-heading --columns=_uuid,match find ACL priority=$OVN_ACL_PRIORITY | grep '$GATEWAY_LSP' | wc -l" 2>/dev/null || echo "0")
        
        if [ "$ACL_COUNT" -ge 2 ]; then
            print_result "Gateway pod has $ACL_COUNT ACL rules (expected: 2+)" "PASS"
        else
            print_result "Gateway pod has $ACL_COUNT ACL rules (expected: 2+)" "FAIL"
        fi
        
        # Check if port security is cleared
        PORT_SECURITY=$(oc exec -n $OVN_NAMESPACE $OVN_POD -c ovn-controller -- bash -c \
            "ovn-nbctl get Logical_Switch_Port $GATEWAY_LSP port_security" 2>/dev/null || echo "error")
        
        if [ "$PORT_SECURITY" = "[]" ]; then
            print_result "Gateway pod port security is cleared" "PASS"
        else
            print_result "Gateway pod port security: $PORT_SECURITY (expected: [])" "FAIL"
        fi
    else
        print_result "OVN pod not found on node $GATEWAY_NODE" "FAIL"
    fi
    echo ""
fi

# Test 6: Check OVN ACLs for business pod
if [ -n "$BUSINESS_POD" ] && [ "$BUSINESS_STATUS" = "Running" ]; then
    echo "Test 6: Business Pod OVN Configuration"
    
    BUSINESS_NODE=$(oc get pod -n $BUSINESS_NAMESPACE $BUSINESS_POD -o jsonpath='{.spec.nodeName}')
    BUSINESS_LSP="${BUSINESS_NAMESPACE}_${BUSINESS_POD}"
    OVN_POD=$(oc get pods -n $OVN_NAMESPACE --field-selector spec.nodeName=$BUSINESS_NODE -l app=ovnkube-node -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$OVN_POD" ]; then
        # Check for ACLs with priority 31821
        ACL_COUNT=$(oc exec -n $OVN_NAMESPACE $OVN_POD -c ovn-controller -- bash -c \
            "ovn-nbctl --format=csv --no-heading --columns=_uuid,match find ACL priority=$OVN_ACL_PRIORITY | grep '$BUSINESS_LSP' | wc -l" 2>/dev/null || echo "0")
        
        if [ "$ACL_COUNT" -ge 2 ]; then
            print_result "Business pod has $ACL_COUNT ACL rules (expected: 2+)" "PASS"
        else
            print_result "Business pod has $ACL_COUNT ACL rules (expected: 2+)" "FAIL"
        fi
        
        # Check if port security is kept
        PORT_SECURITY=$(oc exec -n $OVN_NAMESPACE $OVN_POD -c ovn-controller -- bash -c \
            "ovn-nbctl get Logical_Switch_Port $BUSINESS_LSP port_security" 2>/dev/null || echo "error")
        
        if [ "$PORT_SECURITY" != "[]" ] && [ "$PORT_SECURITY" != "error" ]; then
            print_result "Business pod port security is kept" "PASS"
        else
            print_result "Business pod port security: $PORT_SECURITY (expected: not [])" "FAIL"
        fi
    else
        print_result "OVN pod not found on node $BUSINESS_NODE" "FAIL"
    fi
    echo ""
fi

# Test 7: Check controller logs for errors
echo "Test 7: Controller Logs Check"
CONTROLLER_POD=$(oc get pod -n $GATEWAY_NAMESPACE -l app=apb-controller -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$CONTROLLER_POD" ]; then
    ERROR_COUNT=$(oc logs -n $GATEWAY_NAMESPACE $CONTROLLER_POD --tail=100 2>/dev/null | grep -i "error\|exception\|failed" | wc -l)
    if [ "$ERROR_COUNT" -eq 0 ]; then
        print_result "No errors in recent controller logs" "PASS"
    else
        print_result "Found $ERROR_COUNT error messages in logs" "WARN"
        echo "Recent errors:"
        oc logs -n $GATEWAY_NAMESPACE $CONTROLLER_POD --tail=100 | grep -i "error\|exception\|failed" | tail -5
    fi
else
    print_result "Controller pod not found" "FAIL"
fi
echo ""

# Summary
echo "=========================================="
echo "Test Suite Complete"
echo "=========================================="
echo ""
echo "To view detailed controller logs:"
echo "  oc logs -f deployment/apb-controller -n $GATEWAY_NAMESPACE"
echo ""
echo "To manually check OVN configuration:"
echo "  # For gateway pod:"
echo "  oc exec -n $OVN_NAMESPACE <ovn-pod> -c ovn-controller -- ovn-nbctl find ACL priority=$OVN_ACL_PRIORITY"
echo ""
