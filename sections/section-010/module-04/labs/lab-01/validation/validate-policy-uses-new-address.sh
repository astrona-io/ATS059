#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway2_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')"
gateway2_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')"
# The policy must use the address of the second gateway.
ips="$(kubectl get ciliumegressgatewaypolicies -o jsonpath='{range .items[*]}{.spec.egressGateway.egressIP}{"\n"}{end}' 2>/dev/null)"
if printf '%s\n' "$ips" | grep -qx "$gateway2_ip"; then
  echo "PASS: egressIP is ${gateway2_ip}"
  exit 0
fi
echo "FAIL: no policy has egressIP ${gateway2_ip}"
exit 1
