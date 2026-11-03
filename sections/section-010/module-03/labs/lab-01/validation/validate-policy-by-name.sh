#!/usr/bin/env bash
set -uo pipefail
partner_name="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')"
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
policies="$(kubectl -n starfleet get ciliumnetworkpolicies -o json 2>/dev/null)"
# One policy must select app=shuttle and allow the partner name on port 8080.
count="$(printf '%s' "$policies" | jq --arg n "$partner_name" '[.items[] | select(.spec.endpointSelector.matchLabels.app == "shuttle") | select([.spec.egress[]? | select(any(.toFQDNs[]?; .matchName == $n)) | select(any(.toPorts[]?.ports[]?; .port == "8080"))] | length > 0)] | length' 2>/dev/null)"
if [ "${count:-0}" -ge 1 ]; then
  echo "PASS: a policy allows ${partner_name} on port 8080 for shuttle"
  exit 0
fi
echo "FAIL: no CiliumNetworkPolicy for app=shuttle allows toFQDNs matchName ${partner_name} on port 8080"
exit 1
