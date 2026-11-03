#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway2_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')"
gateway2_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')"
# The policy must select the gateway by role label.
role="$(kubectl get ciliumegressgatewaypolicies -o jsonpath='{range .items[*]}{.spec.egressGateway.nodeSelector.matchLabels.role}{"\n"}{end}' 2>/dev/null)"
if printf '%s\n' "$role" | grep -qx 'egress-gateway'; then
  echo "PASS: a gateway policy selects role=egress-gateway"
  exit 0
fi
echo "FAIL: no CiliumEgressGatewayPolicy has nodeSelector matchLabels role=egress-gateway"
exit 1
