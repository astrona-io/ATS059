#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
gateway_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')"
# A CiliumEgressGatewayPolicy must select app=shuttle in starfleet and list the partner /32.
policies="$(kubectl get ciliumegressgatewaypolicies -o json 2>/dev/null)"
if [ -z "$policies" ]; then
  echo "FAIL: cannot read CiliumEgressGatewayPolicy resources"
  exit 1
fi
count="$(kubectl get ciliumegressgatewaypolicies -o jsonpath='{range .items[*]}{.spec.selectors[*].podSelector.matchLabels.app}{"|"}{.spec.selectors[*].podSelector.matchLabels.io\.kubernetes\.pod\.namespace}{"|"}{.spec.destinationCIDRs[*]}{"\n"}{end}' 2>/dev/null | grep -c "^shuttle|starfleet|.*${partner_ip}/32")"
if [ "$count" -ge 1 ]; then
  echo "PASS: a gateway policy selects shuttle in starfleet and lists ${partner_ip}/32"
  exit 0
fi
echo "FAIL: no CiliumEgressGatewayPolicy selects app=shuttle in starfleet with destination ${partner_ip}/32"
exit 1
