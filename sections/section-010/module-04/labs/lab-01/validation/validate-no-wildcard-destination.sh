#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway2_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')"
gateway2_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')"
# No gateway policy may use a wildcard destination.
all="$(kubectl get ciliumegressgatewaypolicies -o jsonpath='{range .items[*]}{.spec.destinationCIDRs[*]}{"\n"}{end}' 2>/dev/null)"
if [ -z "$all" ]; then
  echo "FAIL: no CiliumEgressGatewayPolicy found"
  exit 1
fi
if printf '%s\n' "$all" | tr ' ' '\n' | grep -qE '^(0\.0\.0\.0/0|::/0)$'; then
  echo "FAIL: a policy uses a wildcard destination"
  exit 1
fi
echo "PASS: no wildcard destination in gateway policies"
exit 0
