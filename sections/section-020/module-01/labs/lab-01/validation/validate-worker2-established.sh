#!/usr/bin/env bash
set -uo pipefail
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
router_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')"
local_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
# The session of worker number 2 must be established.
worker="$(printf '%s\n' $workers | sed -n '2p')"
if [ -z "$worker" ]; then
  echo "FAIL: worker 2 not found"
  exit 1
fi
states="$(kubectl get ciliumbgpnodeconfigs "$worker" -o jsonpath='{.status.bgpInstances[*].peers[*].peeringState}' 2>/dev/null)"
if printf '%s' "$states" | grep -qi 'established'; then
  echo "PASS: $worker reports an established session"
  exit 0
fi
echo "FAIL: $worker peering state is '${states}', expected established"
exit 1
