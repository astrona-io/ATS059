#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
gateway_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')"
# The policy must use the gateway address and select the gateway node.
rows="$(kubectl get ciliumegressgatewaypolicies -o jsonpath='{range .items[*]}{.spec.egressGateway.egressIP}{"|"}{.spec.egressGateway.nodeSelector.matchLabels.kubernetes\.io/hostname}{"\n"}{end}' 2>/dev/null)"
if printf '%s\n' "$rows" | grep -q "^${gateway_ip}|${gateway_node}$"; then
  echo "PASS: egressIP is ${gateway_ip} on node ${gateway_node}"
  exit 0
fi
echo "FAIL: no policy has egressIP ${gateway_ip} with nodeSelector kubernetes.io/hostname=${gateway_node}"
exit 1
