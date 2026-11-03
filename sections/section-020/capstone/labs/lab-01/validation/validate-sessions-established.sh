#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
for worker in $workers; do
  states="$(kubectl get ciliumbgpnodeconfigs "$worker" -o jsonpath='{.status.bgpInstances[*].peers[*].peeringState}' 2>/dev/null)"
  if ! printf '%s' "$states" | grep -qi 'established'; then
    echo "FAIL: ${worker} peering state is '${states}', expected established"
    exit 1
  fi
done
for node in $(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[*].metadata.name}'); do
  if [ -n "$(kubectl get ciliumbgpnodeconfigs "$node" -o name 2>/dev/null)" ]; then
    echo "FAIL: the control plane node ${node} runs BGP"
    exit 1
  fi
done
echo "PASS: both workers have established sessions and the control plane node runs no BGP"
exit 0
