#!/bin/bash
# Run on Jump Host
# Start tcpdump on VM via ssh background
ssh root@192.168.99.12 "timeout 15 tcpdump -nne -i enp1s0 icmp" > /tmp/vm_capture.txt 2>&1 &
PID_TCPDUMP=$!

sleep 2

# Ping from ns-blue
echo "Pinging from ns-blue..."
oc exec -n ns-blue fast-test -- ping -c 2 8.8.8.8

# Ping from ns-red
echo "Pinging from ns-red..."
oc exec -n ns-red fast-test -- ping -c 2 8.8.8.8

wait $PID_TCPDUMP
cat /tmp/vm_capture.txt
