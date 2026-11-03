#!/usr/bin/env bash
set -uo pipefail
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
router_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')"
local_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
# The cluster configuration must select the workers and not the control plane node.
key_value="$(kubectl get ciliumbgpclusterconfigs -o jsonpath='{range .items[*]}{.spec.nodeSelector.matchLabels}{"\n"}{end}' 2>/dev/null | head -n 1)"
if [ -z "$key_value" ]; then
  echo "FAIL: the cluster configuration has no nodeSelector.matchLabels"
  exit 1
fi
for worker in $workers; do
  if [ -z "$(kubectl get ciliumbgpnodeconfigs "$worker" -o name 2>/dev/null)" ]; then
    echo "FAIL: worker ${worker} has no CiliumBGPNodeConfig, so the selector does not match it"
    exit 1
  fi
done
control="$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[*].metadata.name}')"
for node in $control; do
  if [ -n "$(kubectl get ciliumbgpnodeconfigs "$node" -o name 2>/dev/null)" ]; then
    echo "FAIL: the control plane node ${node} runs BGP, only the workers should"
    exit 1
  fi
done
echo "PASS: only the worker nodes have a BGP node configuration"
exit 0
