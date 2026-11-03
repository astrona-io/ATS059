#!/usr/bin/env bash
set -uo pipefail
partner_name="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')"
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
policies="$(kubectl -n starfleet get ciliumnetworkpolicies -o json 2>/dev/null)"
# No wildcard destination in any policy that selects shuttle.
bad="$(printf '%s' "$policies" | jq '[.items[] | select(.spec.endpointSelector.matchLabels.app == "shuttle") | .spec.egress[]? | (.toEntities[]? | select(. == "world" or . == "all")), (.toCIDR[]? | select(. == "0.0.0.0/0")), (.toCIDRSet[]?.cidr | select(. == "0.0.0.0/0")), (.toFQDNs[]?.matchPattern | select(. == "*"))] | length' 2>/dev/null)"
if [ "${bad:-1}" -eq 0 ]; then
  echo "PASS: no wildcard destination in the policies for shuttle"
  exit 0
fi
echo "FAIL: a policy for shuttle allows world, all, 0.0.0.0/0 or every name"
exit 1
