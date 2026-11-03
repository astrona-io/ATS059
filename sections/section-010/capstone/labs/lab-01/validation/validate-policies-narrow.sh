#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
gw="$(kubectl get ciliumegressgatewaypolicies -o jsonpath='{range .items[*]}{.spec.destinationCIDRs[*]}{"\n"}{end}' 2>/dev/null)"
cnp="$(kubectl -n starfleet get ciliumnetworkpolicies -o jsonpath='{range .items[*]}{range .spec.egress[*]}{.toCIDR[*]}{" "}{.toCIDRSet[*].cidr}{" "}{.toEntities[*]}{"\n"}{end}{end}' 2>/dev/null)"
if [ -z "$gw" ] || [ -z "$cnp" ]; then
  echo "FAIL: both a CiliumEgressGatewayPolicy and a CiliumNetworkPolicy in starfleet are required"
  exit 1
fi
if printf '%s\n%s\n' "$gw" "$cnp" | tr ' ' '\n' | grep -qE '^(0\.0\.0\.0/0|::/0|world|all)$'; then
  echo "FAIL: a policy uses a wildcard destination"
  exit 1
fi
echo "PASS: no wildcard destination in the policies"
exit 0
